/**
 *Submitted for verification at Etherscan.io on 2023-03-17
*/

// Sources flattened with hardhat v2.12.2 https://hardhat.org

// File contracts/types/ConsiderationEnums.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// prettier-ignore
enum OrderType {
    // 0: no partial fills, anyone can execute
    FULL_OPEN,

    // 1: partial fills supported, anyone can execute
    PARTIAL_OPEN,

    // 2: no partial fills, only offerer or zone can execute
    FULL_RESTRICTED,

    // 3: partial fills supported, only offerer or zone can execute
    PARTIAL_RESTRICTED
}

// prettier-ignore
enum BasicOrderType {
    // 0: no partial fills, anyone can execute
    ETH_TO_ERC721_FULL_OPEN,

    // 1: partial fills supported, anyone can execute
    ETH_TO_ERC721_PARTIAL_OPEN,

    // 2: no partial fills, only offerer or zone can execute
    ETH_TO_ERC721_FULL_RESTRICTED,

    // 3: partial fills supported, only offerer or zone can execute
    ETH_TO_ERC721_PARTIAL_RESTRICTED,

    // 4: no partial fills, anyone can execute
    ETH_TO_ERC1155_FULL_OPEN,

    // 5: partial fills supported, anyone can execute
    ETH_TO_ERC1155_PARTIAL_OPEN,

    // 6: no partial fills, only offerer or zone can execute
    ETH_TO_ERC1155_FULL_RESTRICTED,

    // 7: partial fills supported, only offerer or zone can execute
    ETH_TO_ERC1155_PARTIAL_RESTRICTED,

    // 8: no partial fills, anyone can execute
    ERC20_TO_ERC721_FULL_OPEN,

    // 9: partial fills supported, anyone can execute
    ERC20_TO_ERC721_PARTIAL_OPEN,

    // 10: no partial fills, only offerer or zone can execute
    ERC20_TO_ERC721_FULL_RESTRICTED,

    // 11: partial fills supported, only offerer or zone can execute
    ERC20_TO_ERC721_PARTIAL_RESTRICTED,

    // 12: no partial fills, anyone can execute
    ERC20_TO_ERC1155_FULL_OPEN,

    // 13: partial fills supported, anyone can execute
    ERC20_TO_ERC1155_PARTIAL_OPEN,

    // 14: no partial fills, only offerer or zone can execute
    ERC20_TO_ERC1155_FULL_RESTRICTED,

    // 15: partial fills supported, only offerer or zone can execute
    ERC20_TO_ERC1155_PARTIAL_RESTRICTED,

    // 16: no partial fills, anyone can execute
    ERC721_TO_ERC20_FULL_OPEN,

    // 17: partial fills supported, anyone can execute
    ERC721_TO_ERC20_PARTIAL_OPEN,

    // 18: no partial fills, only offerer or zone can execute
    ERC721_TO_ERC20_FULL_RESTRICTED,

    // 19: partial fills supported, only offerer or zone can execute
    ERC721_TO_ERC20_PARTIAL_RESTRICTED,

    // 20: no partial fills, anyone can execute
    ERC1155_TO_ERC20_FULL_OPEN,

    // 21: partial fills supported, anyone can execute
    ERC1155_TO_ERC20_PARTIAL_OPEN,

    // 22: no partial fills, only offerer or zone can execute
    ERC1155_TO_ERC20_FULL_RESTRICTED,

    // 23: partial fills supported, only offerer or zone can execute
    ERC1155_TO_ERC20_PARTIAL_RESTRICTED
}

// prettier-ignore
enum BasicOrderRouteType {
    // 0: provide Ether (or other native token) to receive offered ERC721 item.
    ETH_TO_ERC721,

    // 1: provide Ether (or other native token) to receive offered ERC1155 item.
    ETH_TO_ERC1155,

    // 2: provide ERC20 item to receive offered ERC721 item.
    ERC20_TO_ERC721,

    // 3: provide ERC20 item to receive offered ERC1155 item.
    ERC20_TO_ERC1155,

    // 4: provide ERC721 item to receive offered ERC20 item.
    ERC721_TO_ERC20,

    // 5: provide ERC1155 item to receive offered ERC20 item.
    ERC1155_TO_ERC20
}

// prettier-ignore
enum ItemType {
    // 0: ETH on mainnet, MATIC on polygon, etc.
    NATIVE,

    // 1: ERC20 items (ERC777 and ERC20 analogues could also technically work)
    ERC20,

    // 2: ERC721 items
    ERC721,

    // 3: ERC1155 items
    ERC1155,

    // 4: ERC721 items where a number of tokenIds are supported
    ERC721_WITH_CRITERIA,

    // 5: ERC1155 items where a number of ids are supported
    ERC1155_WITH_CRITERIA
}

// prettier-ignore
enum Side {
    // 0: Items that can be spent
    OFFER,

    // 1: Items that must be received
    CONSIDERATION
}


// File contracts/types/ConsiderationStructs.sol

pragma solidity ^0.8.7;

// prettier-ignore

/**
 * @dev An order contains eleven components: an offerer, a zone (or account that
 *      can cancel the order or restrict who can fulfill the order depending on
 *      the type), the order type (specifying partial fill support as well as
 *      restricted order status), the start and end time, a hash that will be
 *      provided to the zone when validating restricted orders, a salt, a key
 *      corresponding to a given conduit, a counter, and an arbitrary number of
 *      offer items that can be spent along with consideration items that must
 *      be received by their respective recipient.
 */
struct OrderComponents {
    address offerer;
    address zone;
    OfferItem[] offer;
    ConsiderationItem[] consideration;
    OrderType orderType;
    uint256 startTime;
    uint256 endTime;
    bytes32 zoneHash;
    uint256 salt;
    bytes32 conduitKey;
    uint256 counter;
}

/**
 * @dev An offer item has five components: an item type (ETH or other native
 *      tokens, ERC20, ERC721, and ERC1155, as well as criteria-based ERC721 and
 *      ERC1155), a token address, a dual-purpose "identifierOrCriteria"
 *      component that will either represent a tokenId or a merkle root
 *      depending on the item type, and a start and end amount that support
 *      increasing or decreasing amounts over the duration of the respective
 *      order.
 */
struct OfferItem {
    ItemType itemType;
    address token;
    uint256 identifierOrCriteria;
    uint256 startAmount;
    uint256 endAmount;
}

/**
 * @dev A consideration item has the same five components as an offer item and
 *      an additional sixth component designating the required recipient of the
 *      item.
 */
struct ConsiderationItem {
    ItemType itemType;
    address token;
    uint256 identifierOrCriteria;
    uint256 startAmount;
    uint256 endAmount;
    address payable recipient;
}

/**
 * @dev For basic orders involving ETH / native / ERC20 <=> ERC721 / ERC1155
 *      matching, a group of six functions may be called that only requires a
 *      subset of the usual order arguments. Note the use of a "basicOrderType"
 *      enum; this represents both the usual order type as well as the "route"
 *      of the basic order (a simple derivation function for the basic order
 *      type is `basicOrderType = orderType + (4 * basicOrderRoute)`.)
 */
struct BasicOrderParameters {
    // calldata offset
    address considerationToken; // 0x24
    uint256 considerationIdentifier; // 0x44
    uint256 considerationAmount; // 0x64
    address payable offerer; // 0x84
    address zone; // 0xa4
    address offerToken; // 0xc4
    uint256 offerIdentifier; // 0xe4
    uint256 offerAmount; // 0x104
    BasicOrderType basicOrderType; // 0x124
    uint256 startTime; // 0x144
    uint256 endTime; // 0x164
    bytes32 zoneHash; // 0x184
    uint256 salt; // 0x1a4
    bytes32 offererConduitKey; // 0x1c4
    bytes32 fulfillerConduitKey; // 0x1e4
    uint256 totalOriginalAdditionalRecipients; // 0x204
    AdditionalRecipient[] additionalRecipients; // 0x224
    bytes signature; // 0x244
    // Total length, excluding dynamic array data: 0x264 (580)
}

/**
 * @dev Basic orders can supply any number of additional recipients, with the
 *      implied assumption that they are supplied from the offered ETH (or other
 *      native token) or ERC20 token for the order.
 */
struct AdditionalRecipient {
    uint256 amount;
    address payable recipient;
}

/**
 * @dev The full set of order components, with the exception of the counter,
 *      must be supplied when fulfilling more sophisticated orders or groups of
 *      orders. The total number of original consideration items must also be
 *      supplied, as the caller may specify additional consideration items.
 */
struct OrderParameters {
    address offerer; // 0x00
    address zone; // 0x20
    OfferItem[] offer; // 0x40
    ConsiderationItem[] consideration; // 0x60
    OrderType orderType; // 0x80
    uint256 startTime; // 0xa0
    uint256 endTime; // 0xc0
    bytes32 zoneHash; // 0xe0
    uint256 salt; // 0x100
    bytes32 conduitKey; // 0x120
    uint256 totalOriginalConsiderationItems; // 0x140
    // offer.length                          // 0x160
}

/**
 * @dev Orders require a signature in addition to the other order parameters.
 */
struct Order {
    OrderParameters parameters;
    bytes signature;
}

/**
 * @dev Advanced orders include a numerator (i.e. a fraction to attempt to fill)
 *      and a denominator (the total size of the order) in addition to the
 *      signature and other order parameters. It also supports an optional field
 *      for supplying extra data; this data will be included in a staticcall to
 *      `isValidOrderIncludingExtraData` on the zone for the order if the order
 *      type is restricted and the offerer or zone are not the caller.
 */
struct AdvancedOrder {
    OrderParameters parameters;
    uint120 numerator;
    uint120 denominator;
    bytes signature;
    bytes extraData;
}

/**
 * @dev A criteria resolver specifies an order, side (offer vs. consideration),
 *      and item index. It then provides a chosen identifier (i.e. tokenId)
 *      alongside a merkle proof demonstrating the identifier meets the required
 *      criteria.
 */
struct CriteriaResolver {
    uint256 orderIndex;
    Side side;
    uint256 index;
    uint256 identifier;
    bytes32[] criteriaProof;
}


// File contracts/interfaces/ConsiderationInterface.sol

pragma solidity ^0.8.7;

// prettier-ignore

/**
 * @title ConsiderationInterface
 * @author 0age
 * @custom:version 1.1
 * @notice Consideration is a generalized ETH/ERC20/ERC721/ERC1155 marketplace.
 *         It minimizes external calls to the greatest extent possible and
 *         provides lightweight methods for common routes as well as more
 *         flexible methods for composing advanced orders.
 *
 * @dev ConsiderationInterface contains all external function interfaces for
 *      Consideration.
 */
interface ConsiderationInterface {
  /**
   * @notice Fulfill an order offering an ERC721 token by supplying Ether (or
   *         the native token for the given chain) as consideration for the
   *         order. An arbitrary number of "additional recipients" may also be
   *         supplied which will each receive native tokens from the fulfiller
   *         as consideration.
   *
   * @param parameters Additional information on the fulfilled order. Note
   *                   that the offerer must first approve this contract (or
   *                   their preferred conduit if indicated by the order) for
   *                   their offered ERC721 token to be transferred.
   *
   * @return fulfilled A boolean indicating whether the order has been
   *                   successfully fulfilled.
   */
  function fulfillBasicOrder(BasicOrderParameters calldata parameters)
    external
    payable
    returns (bool fulfilled);

  /**
   * @notice Fill an order, fully or partially, with an arbitrary number of
   *         items for offer and consideration alongside criteria resolvers
   *         containing specific token identifiers and associated proofs.
   *
   * @param advancedOrder       The order to fulfill along with the fraction
   *                            of the order to attempt to fill. Note that
   *                            both the offerer and the fulfiller must first
   *                            approve this contract (or their preferred
   *                            conduit if indicated by the order) to transfer
   *                            any relevant tokens on their behalf and that
   *                            contracts must implement `onERC1155Received`
   *                            to receive ERC1155 tokens as consideration.
   *                            Also note that all offer and consideration
   *                            components must have no remainder after
   *                            multiplication of the respective amount with
   *                            the supplied fraction for the partial fill to
   *                            be considered valid.
   * @param criteriaResolvers   An array where each element contains a
   *                            reference to a specific offer or
   *                            consideration, a token identifier, and a proof
   *                            that the supplied token identifier is
   *                            contained in the merkle root held by the item
   *                            in question's criteria element. Note that an
   *                            empty criteria indicates that any
   *                            (transferable) token identifier on the token
   *                            in question is valid and that no associated
   *                            proof needs to be supplied.
   * @param fulfillerConduitKey A bytes32 value indicating what conduit, if
   *                            any, to source the fulfiller's token approvals
   *                            from. The zero hash signifies that no conduit
   *                            should be used, with direct approvals set on
   *                            Consideration.
   * @param recipient           The intended recipient for all received items,
   *                            with `address(0)` indicating that the caller
   *                            should receive the items.
   *
   * @return fulfilled A boolean indicating whether the order has been
   *                   successfully fulfilled.
   */
  function fulfillAdvancedOrder(
    AdvancedOrder calldata advancedOrder,
    CriteriaResolver[] calldata criteriaResolvers,
    bytes32 fulfillerConduitKey,
    address recipient
  ) external payable returns (bool fulfilled);
}


// File contracts/interfaces/INonfungiblePositionManager.sol

pragma solidity >=0.7.5;

/// @title Non-fungible token for positions
/// @notice Wraps Uniswap V3 positions in a non-fungible token interface which allows for them to be transferred
/// and authorized.
interface INonfungiblePositionManager {
  /// @notice Returns the position information associated with a given token ID.
  /// @dev Throws if the token ID is not valid.
  /// @param tokenId The ID of the token that represents the position
  /// @return nonce The nonce for permits
  /// @return operator The address that is approved for spending
  /// @return token0 The address of the token0 for a specific pool
  /// @return token1 The address of the token1 for a specific pool
  /// @return fee The fee associated with the pool
  /// @return tickLower The lower end of the tick range for the position
  /// @return tickUpper The higher end of the tick range for the position
  /// @return liquidity The liquidity of the position
  /// @return feeGrowthInside0LastX128 The fee growth of token0 as of the last action on the individual position
  /// @return feeGrowthInside1LastX128 The fee growth of token1 as of the last action on the individual position
  /// @return tokensOwed0 The uncollected amount of token0 owed to the position as of the last computation
  /// @return tokensOwed1 The uncollected amount of token1 owed to the position as of the last computation
  function positions(uint256 tokenId)
    external
    view
    returns (
      uint96 nonce,
      address operator,
      address token0,
      address token1,
      uint24 fee,
      int24 tickLower,
      int24 tickUpper,
      uint128 liquidity,
      uint256 feeGrowthInside0LastX128,
      uint256 feeGrowthInside1LastX128,
      uint128 tokensOwed0,
      uint128 tokensOwed1
    );

  struct DecreaseLiquidityParams {
    uint256 tokenId;
    uint128 liquidity;
    uint256 amount0Min;
    uint256 amount1Min;
    uint256 deadline;
  }

  /// @notice Decreases the amount of liquidity in a position and accounts it to the position
  /// @param params tokenId The ID of the token for which liquidity is being decreased,
  /// amount The amount by which liquidity will be decreased,
  /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
  /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
  /// deadline The time by which the transaction must be included to effect the change
  /// @return amount0 The amount of token0 accounted to the position's tokens owed
  /// @return amount1 The amount of token1 accounted to the position's tokens owed
  function decreaseLiquidity(DecreaseLiquidityParams calldata params)
    external
    payable
    returns (uint256 amount0, uint256 amount1);

  struct CollectParams {
    uint256 tokenId;
    address recipient;
    uint128 amount0Max;
    uint128 amount1Max;
  }

  /// @notice Collects up to a maximum amount of fees owed to a specific position to the recipient
  /// @param params tokenId The ID of the NFT for which tokens are being collected,
  /// recipient The account that should receive the tokens,
  /// amount0Max The maximum amount of token0 to collect,
  /// amount1Max The maximum amount of token1 to collect
  /// @return amount0 The amount of fees collected in token0
  /// @return amount1 The amount of fees collected in token1
  function collect(CollectParams calldata params)
    external
    payable
    returns (uint256 amount0, uint256 amount1);

  /// @notice Burns a token ID, which deletes it from the NFT contract. The token must have 0 liquidity and all tokens
  /// must be collected first.
  /// @param tokenId The ID of the token that is being burned
  function burn(uint256 tokenId) external payable;

  /// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
  /// @dev The `msg.value` should not be trusted for any method callable from multicall.
  /// @param data The encoded function data for each of the calls to make to this contract
  /// @return results The results from each of the calls passed in via data
  function multicall(bytes[] calldata data)
    external
    payable
    returns (bytes[] memory results);
}


// File contracts/interfaces/INFTXMarketplaceZap.sol

pragma solidity ^0.8.13;

interface INFTXMarketplaceZap {
  /// @notice A mapping of NFTX Vault IDs to their address corresponding vault contract address
  function nftxVaultAddresses(uint256) external view returns (address);

  function mintAndSell721(
    uint256 vaultId,
    uint256[] calldata ids,
    uint256 minEthOut,
    address[] calldata path,
    address to
  ) external;

  function mintAndSell721WETH(
    uint256 vaultId,
    uint256[] calldata ids,
    uint256 minWethOut,
    address[] calldata path,
    address to
  ) external;
}


// File contracts/types/OrderTypes.sol

pragma solidity ^0.8.0;

/**
 * @title OrderTypes
 * @notice This library contains order types for the LooksRare exchange.
 */
library OrderTypes {
    // keccak256("MakerOrder(bool isOrderAsk,address signer,address collection,uint256 price,uint256 tokenId,uint256 amount,address strategy,address currency,uint256 nonce,uint256 startTime,uint256 endTime,uint256 minPercentageToAsk,bytes params)")
    bytes32 internal constant MAKER_ORDER_HASH = 0x40261ade532fa1d2c7293df30aaadb9b3c616fae525a0b56d3d411c841a85028;

    struct MakerOrder {
        bool isOrderAsk; // true --> ask / false --> bid
        address signer; // signer of the maker order
        address collection; // collection address
        uint256 price; // price (used as )
        uint256 tokenId; // id of the token
        uint256 amount; // amount of tokens to sell/purchase (must be 1 for ERC721, 1+ for ERC1155)
        address strategy; // strategy for trade execution (e.g., DutchAuction, StandardSaleForFixedPrice)
        address currency; // currency (e.g., WETH)
        uint256 nonce; // order nonce (must be unique unless new maker order is meant to override existing one e.g., lower ask price)
        uint256 startTime; // startTime in timestamp
        uint256 endTime; // endTime in timestamp
        uint256 minPercentageToAsk; // slippage protection (9000 --> 90% of the final price must return to ask)
        bytes params; // additional parameters
        uint8 v; // v: parameter (27 or 28)
        bytes32 r; // r: parameter
        bytes32 s; // s: parameter
    }

    struct TakerOrder {
        bool isOrderAsk; // true --> ask / false --> bid
        address taker; // msg.sender
        uint256 price; // final price for the purchase
        uint256 tokenId;
        uint256 minPercentageToAsk; // // slippage protection (9000 --> 90% of the final price must return to ask)
        bytes params; // other params (e.g., tokenId)
    }

    function hash(MakerOrder memory makerOrder) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    MAKER_ORDER_HASH,
                    makerOrder.isOrderAsk,
                    makerOrder.signer,
                    makerOrder.collection,
                    makerOrder.price,
                    makerOrder.tokenId,
                    makerOrder.amount,
                    makerOrder.strategy,
                    makerOrder.currency,
                    makerOrder.nonce,
                    makerOrder.startTime,
                    makerOrder.endTime,
                    makerOrder.minPercentageToAsk,
                    keccak256(makerOrder.params)
                )
            );
    }
}


// File contracts/interfaces/ILooksRareExchange.sol

pragma solidity ^0.8.0;

interface ILooksRareExchange {
  function matchBidWithTakerAsk(
    OrderTypes.TakerOrder calldata takerAsk,
    OrderTypes.MakerOrder calldata makerBid
  ) external;
}


// File contracts/interfaces/ICryptoPunksMarket.sol

pragma solidity ^0.8.13;

interface ICryptoPunksMarket {
  function punkIndexToAddress(uint256 punkIndex)
    external
    view
    returns (address);

  function balanceOf(address user) external view returns (uint256);

  function transferPunk(address to, uint256 punkIndex) external;

  function withdraw() external;

  function acceptBidForPunk(uint256 punkIndex, uint256 minPrice) external;

  function offerPunkForSaleToAddress(
    uint256 punkIndex,
    uint256 minSalePriceInWei,
    address toAddress
  ) external;
}


// File contracts/interfaces/IUniswapV2Router01.sol


pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
  function factory() external pure returns (address);

  function WETH() external pure returns (address);

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint256 amountADesired,
    uint256 amountBDesired,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  )
    external
    returns (
      uint256 amountA,
      uint256 amountB,
      uint256 liquidity
    );

  function addLiquidityETH(
    address token,
    uint256 amountTokenDesired,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  )
    external
    payable
    returns (
      uint256 amountToken,
      uint256 amountETH,
      uint256 liquidity
    );

  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountA, uint256 amountB);

  function removeLiquidityETH(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountToken, uint256 amountETH);

  function removeLiquidityWithPermit(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountA, uint256 amountB);

  function removeLiquidityETHWithPermit(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountToken, uint256 amountETH);

  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapTokensForExactTokens(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactETHForTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function swapTokensForExactETH(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactTokensForETH(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapETHForExactTokens(
    uint256 amountOut,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function quote(
    uint256 amountA,
    uint256 reserveA,
    uint256 reserveB
  ) external pure returns (uint256 amountB);

  function getAmountOut(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountOut);

  function getAmountIn(
    uint256 amountOut,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountIn);

  function getAmountsOut(uint256 amountIn, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);

  function getAmountsIn(uint256 amountOut, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);
}


// File contracts/interfaces/IUniswapV2Router02.sol


pragma solidity >=0.6.2;

interface IUniswapV2Router02 is IUniswapV2Router01 {
  function removeLiquidityETHSupportingFeeOnTransferTokens(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountETH);

  function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountETH);

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;

  function swapExactETHForTokensSupportingFeeOnTransferTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable;

  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;
}


// File @uniswap/v3-core/contracts/interfaces/callback/[email protected]

pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}


// File @uniswap/v3-periphery/contracts/interfaces/[email protected]

pragma solidity >=0.7.5;

/// @title Self Permit
/// @notice Functionality to call permit on any EIP-2612-compliant token for use in the route
interface ISelfPermit {
    /// @notice Permits this contract to spend a given token from `msg.sender`
    /// @dev The `owner` is always msg.sender and the `spender` is always address(this).
    /// @param token The address of the token spent
    /// @param value The amount that can be spent of token
    /// @param deadline A timestamp, the current blocktime must be less than or equal to this timestamp
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function selfPermit(
        address token,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;

    /// @notice Permits this contract to spend a given token from `msg.sender`
    /// @dev The `owner` is always msg.sender and the `spender` is always address(this).
    /// Can be used instead of #selfPermit to prevent calls from failing due to a frontrun of a call to #selfPermit
    /// @param token The address of the token spent
    /// @param value The amount that can be spent of token
    /// @param deadline A timestamp, the current blocktime must be less than or equal to this timestamp
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function selfPermitIfNecessary(
        address token,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;

    /// @notice Permits this contract to spend the sender's tokens for permit signatures that have the `allowed` parameter
    /// @dev The `owner` is always msg.sender and the `spender` is always address(this)
    /// @param token The address of the token spent
    /// @param nonce The current nonce of the owner
    /// @param expiry The timestamp at which the permit is no longer valid
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function selfPermitAllowed(
        address token,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;

    /// @notice Permits this contract to spend the sender's tokens for permit signatures that have the `allowed` parameter
    /// @dev The `owner` is always msg.sender and the `spender` is always address(this)
    /// Can be used instead of #selfPermitAllowed to prevent calls from failing due to a frontrun of a call to #selfPermitAllowed.
    /// @param token The address of the token spent
    /// @param nonce The current nonce of the owner
    /// @param expiry The timestamp at which the permit is no longer valid
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function selfPermitAllowedIfNecessary(
        address token,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;
}


// File @uniswap/v3-periphery/contracts/interfaces/[email protected]

pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Multicall interface
/// @notice Enables calling multiple methods in a single call to the contract
interface IMulticall {
    /// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
    /// @dev The `msg.value` should not be trusted for any method callable from multicall.
    /// @param data The encoded function data for each of the calls to make to this contract
    /// @return results The results from each of the calls passed in via data
    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);
}


// File contracts/interfaces/IUniSwapV3Router02.sol

pragma solidity 0.8.13;



/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V2
interface IV2SwapRouter {
  /// @notice Swaps `amountIn` of one token for as much as possible of another token
  /// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
  /// and swap the entire amount, enabling contracts to send tokens before calling this function.
  /// @param amountIn The amount of token to swap
  /// @param amountOutMin The minimum amount of output that must be received
  /// @param path The ordered list of tokens to swap through
  /// @param to The recipient address
  /// @return amountOut The amount of the received token
  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to
  ) external payable returns (uint256 amountOut);

  /// @notice Swaps as little as possible of one token for an exact amount of another token
  /// @param amountOut The amount of token to swap for
  /// @param amountInMax The maximum amount of input that the caller will pay
  /// @param path The ordered list of tokens to swap through
  /// @param to The recipient address
  /// @return amountIn The amount of token to pay
  function swapTokensForExactTokens(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to
  ) external payable returns (uint256 amountIn);
}

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface IV3SwapRouter is IUniswapV3SwapCallback {
  struct ExactInputSingleParams {
    address tokenIn;
    address tokenOut;
    uint24 fee;
    address recipient;
    uint256 amountIn;
    uint256 amountOutMinimum;
    uint160 sqrtPriceLimitX96;
  }

  /// @notice Swaps `amountIn` of one token for as much as possible of another token
  /// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
  /// and swap the entire amount, enabling contracts to send tokens before calling this function.
  /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
  /// @return amountOut The amount of the received token
  function exactInputSingle(ExactInputSingleParams calldata params)
    external
    payable
    returns (uint256 amountOut);

  struct ExactInputParams {
    bytes path;
    address recipient;
    uint256 amountIn;
    uint256 amountOutMinimum;
  }

  /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
  /// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
  /// and swap the entire amount, enabling contracts to send tokens before calling this function.
  /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
  /// @return amountOut The amount of the received token
  function exactInput(ExactInputParams calldata params)
    external
    payable
    returns (uint256 amountOut);

  struct ExactOutputSingleParams {
    address tokenIn;
    address tokenOut;
    uint24 fee;
    address recipient;
    uint256 amountOut;
    uint256 amountInMaximum;
    uint160 sqrtPriceLimitX96;
  }

  /// @notice Swaps as little as possible of one token for `amountOut` of another token
  /// that may remain in the router after the swap.
  /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
  /// @return amountIn The amount of the input token
  function exactOutputSingle(ExactOutputSingleParams calldata params)
    external
    payable
    returns (uint256 amountIn);

  struct ExactOutputParams {
    bytes path;
    address recipient;
    uint256 amountOut;
    uint256 amountInMaximum;
  }

  /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
  /// that may remain in the router after the swap.
  /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
  /// @return amountIn The amount of the input token
  function exactOutput(ExactOutputParams calldata params)
    external
    payable
    returns (uint256 amountIn);
}

/// @title MulticallExtended interface
/// @notice Enables calling multiple methods in a single call to the contract with optional validation
interface IMulticallExtended is IMulticall {
  /// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
  /// @dev The `msg.value` should not be trusted for any method callable from multicall.
  /// @param deadline The time by which this function must be called before failing
  /// @param data The encoded function data for each of the calls to make to this contract
  /// @return results The results from each of the calls passed in via data
  function multicall(uint256 deadline, bytes[] calldata data)
    external
    payable
    returns (bytes[] memory results);

  /// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
  /// @dev The `msg.value` should not be trusted for any method callable from multicall.
  /// @param previousBlockhash The expected parent blockHash
  /// @param data The encoded function data for each of the calls to make to this contract
  /// @return results The results from each of the calls passed in via data
  function multicall(bytes32 previousBlockhash, bytes[] calldata data)
    external
    payable
    returns (bytes[] memory results);
}

/// @title Router token swapping functionality
interface IUniSwapV3Router02 is
  IV2SwapRouter,
  IV3SwapRouter,
  IMulticallExtended,
  ISelfPermit
{

}


// File @openzeppelin/contracts/utils/introspection/[email protected]

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


// File @openzeppelin/contracts/token/ERC721/[email protected]

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

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


// File contracts/interfaces/IWrappedPunks.sol

pragma solidity ^0.8.13;

/**
 * @dev Interface for a permittable ERC721 contract
 * See https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC72 allowance (see {IERC721-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC721-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IWrappedPunks is IERC721 {
  function punkContract() external view returns (address);

  function mint(uint256 punkIndex) external;

  function burn(uint256 punkIndex) external;

  function registerProxy() external;

  function proxyInfo(address user) external view returns (address proxy);
}


// File contracts/interfaces/ILSSVMRouter.sol

pragma solidity ^0.8.13;

struct PairSwapSpecific {
  address pair;
  uint256[] nftIds;
}

interface ILSSVMRouter {
  /**
    @notice Swaps NFTs into ETH/ERC20 using multiple pairs.
    @param swapList The list of pairs to trade with and the IDs of the NFTs to sell to each.
    @param minOutput The minimum acceptable total tokens received
    @param tokenRecipient The address that will receive the token output
    @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
    @return outputAmount The total tokens received
  */
  function swapNFTsForToken(
    PairSwapSpecific[] calldata swapList,
    uint256 minOutput,
    address tokenRecipient,
    uint256 deadline
  ) external returns (uint256 outputAmount);
}


// File contracts/types/DataTypes.sol

pragma solidity ^0.8.13;

/**
 * @title DataTypes
 * @notice This library contains Data types for the paraspace market.
 */
library DataTypes {
  struct Credit {
    address token;
    uint256 amount;
    bytes orderId;
    uint8 v;
    bytes32 r;
    bytes32 s;
  }
}


// File contracts/types/LiquidatorDataTypes.sol

pragma solidity ^0.8.13;




struct SwapParams {
  bool isSwapV3;
  address router;
  bytes v3Path;
  address[] v2Path;
}

enum TokenType {
  NONE,
  ERC20,
  ERC721,
  ATOKEN,
  CETH,
  CERC20,
  CAPE,
  BWETH,
  YAPE
}

struct AssetParams {
  address token;
  TokenType tokenType;
}

enum MarketType {
  SEAPORT_BASIC,
  SEAPORT_COLLECTION,
  LOOKSRARE,
  PARASPACE,
  CRYPTOPUNKS,
  UNIV3POS,
  NFTX,
  SUDO
}

struct LiquidateCallParams {
  address collateralAsset;
  uint256 tokenId;
  address user;
  uint256 liquidationAmount; // equals flashLoanAmount and flashLoanAsset is limited to WETH
}

struct FlashLoanParams {
  SwapParams offerToFlashLoan;
}

struct SeaportBasicLiquidateERC721Params {
  BasicOrderParameters order;
  address market; // seaport
  address nftApprover; // conduit
  LiquidateCallParams liquidateParams;
  FlashLoanParams flashLoanParams;
}

struct AdvancedOrderParameters {
  AdvancedOrder advancedOrder;
  CriteriaResolver[] criteriaResolvers;
  bytes32 fulfillerConduitKey;
  address recipient;
}

struct SeaportAdvancedLiquidateERC721Params {
  AdvancedOrderParameters order;
  address market; // seaport
  address nftApprover; // conduit
  LiquidateCallParams liquidateParams;
  FlashLoanParams flashLoanParams;
}

struct LooksRareLiquidateERC721Params {
  OrderTypes.TakerOrder takerAsk;
  OrderTypes.MakerOrder makerBid;
  address market; // looksRareExchange
  address nftApprover; // transferManagerERC721
  LiquidateCallParams liquidateParams;
  FlashLoanParams flashLoanParams;
}

struct AcceptBidWithCreditParams {
  bytes32 marketplaceId;
  bytes data;
  DataTypes.Credit credit;
  address onBehalfOf;
  uint16 referralCode;
}

struct ParaspaceLiquidateERC721Params {
  AcceptBidWithCreditParams acceptBidInfo;
  address nftApprover; // paraspace seaport or conduit address
  LiquidateCallParams liquidateParams;
  FlashLoanParams flashLoanParams;
}

struct CryptoPunksBid {
  uint256 punkIndex;
  address punkContract;
  address offerToken; // WETH
  uint256 amount; // value
}

// sell cryptopunks on CryptoPunksMarket contract
struct LiquidateCryptoPunksParams {
  CryptoPunksBid bid;
  LiquidateCallParams liquidateParams;
  FlashLoanParams flashLoanParams;
}

struct UniV3POSInfo {
  uint256 tokenId;
  address posManager;
  address offerToken;
  SwapParams swapToken0;
  SwapParams swapToken1;
}

// removeLiquidity and collect fees
struct LiquidateUniV3POSParams {
  UniV3POSInfo info;
  LiquidateCallParams liquidateParams;
  FlashLoanParams flashLoanParams;
}

// NFTX fullQuote params
struct NFTXQuote {
  bool isPunk;
  uint256 vaultId;
  uint256 nftId;
  address buyToken;
  uint256 minWethOut;
  address[] swapPath;
}

// NFTX market
struct NFTXLiquidateERC721Params {
  NFTXQuote quote;
  address market; // NFTXMarketplaceZap
  LiquidateCallParams liquidateParams;
  FlashLoanParams flashLoanParams;
}

// sudoswap swapNFTsForToken params
struct SudoQuote {
  address pair;
  uint256 nftId;
  uint256 minOutput;
  address outToken;
}

// SudoSwap market
struct SudoLiquidateERC721Params {
  SudoQuote quote;
  address market; // LSSVMRouter
  LiquidateCallParams liquidateParams;
  FlashLoanParams flashLoanParams;
}

struct UnstakeAndRepayParams {
  address nftAsset;
  uint256 tokenId;
}


// File contracts/interfaces/IPool.sol

pragma solidity ^0.8.13;

/**
 * @title IPool
 *
 * @notice Defines the basic interface for an Paraspace Pool.
 **/
interface IPool {
  /**
   * @notice Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
   * - The caller (liquidator) covers `liquidationAmount` amount of debt of the user getting liquidated, and receives
   *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param liquidationAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param liquidationAmount The debt amount of borrowed `asset` the liquidator wants to cover
   * @param receivePToken True if the liquidators wants to receive the collateral xTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   **/
  function liquidateERC20(
    address collateralAsset,
    address liquidationAsset,
    address user,
    uint256 liquidationAmount,
    bool receivePToken
  ) external payable;

  function liquidateERC721(
    address collateralAsset,
    address user,
    uint256 collateralTokenId,
    uint256 liquidationAmount,
    bool receiveNToken
  ) external payable;

  /**
   * @notice Implements the acceptBidWithCredit feature. AcceptBidWithCredit allows users to
   * accept a leveraged bid on ParaSpace NFT marketplace. Users can submit leveraged bid and pay
   * at most (1 - LTV) * $NFT
   * @dev The nft receiver just needs to do the downpayment
   * @param marketplaceId The marketplace identifier
   * @param payload The encoded parameters to be passed to marketplace contract (selector eliminated)
   * @param credit The credit that user would like to use for this purchase
   * @param onBehalfOf Address of the user who will sell the NFT
   * @param referralCode The referral code used
   */
  function acceptBidWithCredit(
    bytes32 marketplaceId,
    bytes calldata payload,
    DataTypes.Credit calldata credit,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  function unstakeApePositionAndRepay(
    address nftAsset,
    uint256 tokenId
  ) external;

  /**
   * @notice Withdraws an `amount` of underlying asset from the reserve, burning the equivalent xTokens owned
   * E.g. User has 100 pUSDC, calls withdraw() and receives 100 USDC, burning the 100 pUSDC
   * @param asset The address of the underlying asset to withdraw
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole xToken balance
   * @param to The address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   * @return The final amount withdrawn
   **/
  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external returns (uint256);

  /**
   * @notice Withdraws multiple `tokenIds` of underlying ERC721  asset from the reserve, burning the equivalent nTokens owned
   * E.g. User has 2 nBAYC, calls withdraw() and receives 2 BAYC, burning the 2 nBAYC
   * @param asset The address of the underlying asset to withdraw
   * @param tokenIds The underlying tokenIds to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole xToken balance
   * @param to The address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   * @return The final amount withdrawn
   **/
  function withdrawERC721(
    address asset,
    uint256[] calldata tokenIds,
    address to
  ) external returns (uint256);
}


// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File contracts/interfaces/IWETH.sol

pragma solidity ^0.8.13;

interface IWETH is IERC20 {
  function deposit() external payable;

  function transfer(address to, uint256 value) external returns (bool);

  function withdraw(uint256) external;

  function balanceOf(address account) external view returns (uint256);
}


// File @openzeppelin/contracts/utils/[email protected]

// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;



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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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


// File contracts/lib/LiquidatorLib.sol

pragma solidity ^0.8.13;














library LiquidatorLib {
  using SafeERC20 for IERC20;

  /**
   * @dev using seaport fulfillBasicOrder function to fulfill bid
   * @param _seaport    seaport address : opensea seaport or paraspace seaport
   * @param _conduit    fulfiller conduit address
   */
  function fulfillBasicOrder(
    BasicOrderParameters memory parameters,
    address _seaport,
    address _conduit
  ) external returns (bool fulfilled) {
    IERC721(parameters.considerationToken).setApprovalForAll(_conduit, true);
    return ConsiderationInterface(_seaport).fulfillBasicOrder(parameters);
  }

  /**
   * @dev using seaport fulfillAdvancedOrder function to fulfill collection bid
   * @param _seaport    seaport address : opensea seaport or paraspace seaport
   * @param _conduit    fulfiller conduit address
   */
  function fulfillAdvancedOrder(
    AdvancedOrderParameters memory parameters,
    address _seaport,
    address _conduit
  ) external returns (bool fulfilled) {
    address considerationToken = parameters
      .advancedOrder
      .parameters
      .consideration[0]
      .token;
    _safeERC721Approve(considerationToken, _conduit, true);

    if (parameters.advancedOrder.parameters.consideration.length > 1) {
      address offerToken = parameters.advancedOrder.parameters.offer[0].token;
      uint256 offerAmount = parameters
        .advancedOrder
        .parameters
        .offer[0]
        .startAmount;
      _safeERC20Approve(offerToken, _conduit, offerAmount);
    }

    return
      ConsiderationInterface(_seaport).fulfillAdvancedOrder(
        parameters.advancedOrder,
        parameters.criteriaResolvers,
        parameters.fulfillerConduitKey,
        parameters.recipient
      );
  }

  /**
   * @dev using looksrare matchBidWithTakerAsk function to fulfill standard or collection bid
   * @param takerAsk    accept bid info
   * @param makerBid    bid order
   * @param _looksRareExchange    looksRareExchange address
   * @param _transferManager    nft approve
   */
  function matchBidWithTakerAsk(
    OrderTypes.TakerOrder memory takerAsk,
    OrderTypes.MakerOrder memory makerBid,
    address _looksRareExchange,
    address _transferManager
  ) external {
    _safeERC721Approve(makerBid.collection, _transferManager, true);
    ILooksRareExchange(_looksRareExchange).matchBidWithTakerAsk(
      takerAsk,
      makerBid
    );
  }

  /**
   * @dev using function `pool.acceptBidWithCredit` to sell nft on paraspace marketplace
   * @param params    params of `pool.acceptBidWithCredit`
   * @param nft       nft collection address
   * @param approver  paraspace seaport or conduit address
   */
  function acceptBidWithCredit(
    AcceptBidWithCreditParams memory params,
    address pool,
    address nft,
    address approver
  ) external {
    _safeERC721Approve(nft, approver, true);

    IPool(pool).acceptBidWithCredit(
      params.marketplaceId,
      params.data,
      params.credit,
      params.onBehalfOf,
      params.referralCode
    );

    IPool(pool).withdraw(params.credit.token, type(uint256).max, address(this));
  }

  /**
   * @dev using CryptoPunksMarket acceptBidForPunk function to fulfill punk bid
   * @param _wpunk  wpunk address
   * @param bid     bid information
   */
  function acceptBidForPunk(
    address _wpunk,
    CryptoPunksBid memory bid
  ) external {
    IWrappedPunks(_wpunk).burn(bid.punkIndex);

    ICryptoPunksMarket punk = ICryptoPunksMarket(bid.punkContract);
    punk.acceptBidForPunk(bid.punkIndex, bid.amount);
    punk.withdraw();

    IWETH(bid.offerToken).deposit{ value: address(this).balance }();
  }

  /**
   * @dev remove UNIV3POS liquidity and collect fees to get some token0 and token1
   * @param params UNIV3POS Information
   */
  function uniV3RemoveLiquidityAndCollection(
    UniV3POSInfo memory params
  ) external {
    INonfungiblePositionManager posManager = INonfungiblePositionManager(
      params.posManager
    );
    uint256 tokenId = params.tokenId;
    address weth = params.offerToken;
    (
      ,
      ,
      address token0,
      address token1,
      ,
      ,
      ,
      uint128 liquidity,
      ,
      ,
      ,

    ) = posManager.positions(tokenId);

    bytes[] memory data = new bytes[](3);

    data[0] = abi.encodeWithSelector(
      posManager.decreaseLiquidity.selector,
      INonfungiblePositionManager.DecreaseLiquidityParams({
        tokenId: tokenId,
        liquidity: liquidity,
        amount0Min: 0,
        amount1Min: 0,
        deadline: block.timestamp
      })
    );

    data[1] = abi.encodeWithSelector(
      posManager.collect.selector,
      INonfungiblePositionManager.CollectParams({
        tokenId: tokenId,
        recipient: address(this),
        amount0Max: type(uint128).max,
        amount1Max: type(uint128).max
      })
    );

    data[2] = abi.encodeWithSelector(posManager.burn.selector, tokenId);

    posManager.multicall(data);

    if (weth != token0) {
      _swapExactTokensForTokens(
        token0,
        IERC20(token0).balanceOf(address(this)),
        0,
        params.swapToken0
      );
    }
    if (weth != token1) {
      _swapExactTokensForTokens(
        token1,
        IERC20(token1).balanceOf(address(this)),
        0,
        params.swapToken1
      );
    }
  }

  /**
   * @dev using NFTXMarketplaceZap.mintAndSell721WETH to sell nft
   * @param quote NFTX market api quote
   * @param nft nft address
   * @param nftxMarket NFTXMarketplaceZap address
   */
  function nftxMintAndSell721(
    NFTXQuote memory quote,
    address nft,
    address nftxMarket
  ) external {
    if (quote.isPunk) {
      IWrappedPunks wpunk = IWrappedPunks(nft);
      wpunk.burn(quote.nftId);
      ICryptoPunksMarket punk = ICryptoPunksMarket(wpunk.punkContract());
      punk.offerPunkForSaleToAddress(quote.nftId, 0, nftxMarket);
    } else {
      _safeERC721Approve(nft, nftxMarket, true);
    }

    uint256[] memory ids = new uint256[](1);
    ids[0] = quote.nftId;

    INFTXMarketplaceZap(nftxMarket).mintAndSell721WETH(
      quote.vaultId,
      ids,
      quote.minWethOut,
      quote.swapPath,
      address(this)
    );
  }

  /**
   * @dev using LSSVMRouter.swapNFTsForToken to sell nft
   * @param quote sudoswap quote
   * @param nft nft address
   * @param sudoRouter sudoswap LSSVMRouter address
   */
  function sudoSwapNFTsForToken(
    SudoQuote memory quote,
    address nft,
    address sudoRouter
  ) external {
    _safeERC721Approve(nft, sudoRouter, true);

    uint256[] memory nftIds = new uint256[](1);
    nftIds[0] = quote.nftId;

    PairSwapSpecific[] memory swapList = new PairSwapSpecific[](1);
    swapList[0] = PairSwapSpecific({ pair: quote.pair, nftIds: nftIds });

    ILSSVMRouter(sudoRouter).swapNFTsForToken(
      swapList,
      quote.minOutput,
      address(this),
      block.timestamp
    );

    IWETH(quote.outToken).deposit{ value: address(this).balance }();
  }

  /**
   * @dev safeApprove to 0 and then safeApprove to `_amount`
   *
   * IMPORTANT: This logic is required for compatibility for USDT or other
   * token with this kind of compatibility issue. It's not needed for most
   * other tokens.
   */
  function _safeERC20Approve(
    address _token,
    address _spender,
    uint256 _amount
  ) internal {
    IERC20 token = IERC20(_token);
    if (token.allowance(address(this), _spender) < _amount) {
      token.safeApprove(_spender, 0);
      token.safeApprove(_spender, type(uint256).max);
    }
  }

  /**
   * @dev check the NFT approved status before `setApprovalForAll`
   */
  function _safeERC721Approve(
    address _token,
    address _spender,
    bool _approved
  ) internal {
    if (
      IERC721(_token).isApprovedForAll(address(this), _spender) != _approved
    ) {
      IERC721(_token).setApprovalForAll(_spender, _approved);
    }
  }

  /**
   * @dev uniswapV2: swapTokensForExactTokens
   *      uniswapV3: exactOutput
   */
  function _swapTokensForExactTokens(
    address tokenIn,
    uint256 amountInMax,
    uint256 amountOut,
    SwapParams memory params
  ) internal {
    _safeERC20Approve(tokenIn, params.router, amountInMax);

    if (params.isSwapV3) {
      IV3SwapRouter(params.router).exactOutput(
        IV3SwapRouter.ExactOutputParams({
          path: params.v3Path,
          recipient: address(this),
          amountOut: amountOut,
          amountInMaximum: amountInMax
        })
      );
    } else {
      IUniswapV2Router02(params.router).swapTokensForExactTokens(
        amountOut,
        amountInMax,
        params.v2Path,
        address(this),
        block.timestamp
      );
    }
  }

  /**
   * @dev uniswapV2: swapExactTokensForTokens
   *      uniswapV3: exactInput
   */
  function _swapExactTokensForTokens(
    address tokenIn,
    uint256 amountIn,
    uint256 amountOutMin,
    SwapParams memory params
  ) internal {
    _safeERC20Approve(tokenIn, params.router, amountIn);

    if (params.isSwapV3) {
      IV3SwapRouter(params.router).exactInput(
        IV3SwapRouter.ExactInputParams({
          path: params.v3Path,
          recipient: address(this),
          amountIn: amountIn,
          amountOutMinimum: amountOutMin
        })
      );
    } else {
      IUniswapV2Router02(params.router).swapExactTokensForTokens(
        amountIn,
        amountOutMin,
        params.v2Path,
        address(this),
        block.timestamp
      );
    }
  }
}