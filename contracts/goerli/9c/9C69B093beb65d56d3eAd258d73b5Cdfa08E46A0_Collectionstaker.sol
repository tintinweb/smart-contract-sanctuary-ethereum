// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

contract CurveErrorCodes {
    enum Error {
        OK, // No error
        INVALID_NUMITEMS, // The numItem value is 0
        SPOT_PRICE_OVERFLOW, // The updated spot price doesn't fit into 128 bits
        TOO_MANY_ITEMS // The value of numItems passes was too great
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";

import {ICollectionPool} from "../pools/ICollectionPool.sol";
import {CollectionPool} from "../pools/CollectionPool.sol";
import {ICollectionPoolFactory} from "../pools/ICollectionPoolFactory.sol";
import {CurveErrorCodes} from "../bonding-curves/CurveErrorCodes.sol";

contract MultiRouter {
    using SafeTransferLib for address payable;
    using SafeTransferLib for ERC20;

    ICollectionPoolFactory public immutable erc721factory;

    constructor(ICollectionPoolFactory _erc721factory) {
        erc721factory = _erc721factory;
    }

    struct PoolSwapSpecific {
        CollectionPool pool;
        uint256[] nftIds;
        bytes32[] proof;
        bool[] proofFlags;
        bytes32[] proofLeaves;
    }

    struct RobustPoolSwapSpecificWithToken {
        PoolSwapSpecific swapInfo;
        uint256 maxCost;
        bool isETHSwap;
    }

    struct RobustPoolSwapSpecificForToken {
        PoolSwapSpecific swapInfo;
        uint256 minOutput;
    }

    struct RobustPoolNFTsForTokenAndTokenforNFTsTrade {
        RobustPoolSwapSpecificWithToken[] tokenToNFTTradesSpecific;
        RobustPoolSwapSpecificForToken[] nftToTokenTrades;
    }

    /**
     * @notice Buys NFTs with ETH and ERC20s and sells them for tokens in one transaction
     * @param params All the parameters for the swap (packed in struct to avoid stack too deep), containing:
     * - tokenToNFTTradesSpecific The list of NFTs to buy
     * - nftToTokenSwapList The list of NFTs to sell
     * - inputAmount The max amount of tokens to send (if ERC20)
     * - tokenRecipient The address that receives tokens from the NFTs sold
     * - nftRecipient The address that receives NFTs
     */
    function robustSwapTokensForSpecificNFTsAndNFTsToToken(RobustPoolNFTsForTokenAndTokenforNFTsTrade calldata params)
        external
        payable
        returns (uint256 remainingETHValue)
    {
        // Attempt to fill each buy order for specific NFTs
        {
            remainingETHValue = msg.value;
            uint256 poolCost;
            CurveErrorCodes.Error error;
            uint256 numSwaps = params.tokenToNFTTradesSpecific.length;
            for (uint256 i; i < numSwaps;) {
                // Calculate actual cost per swap
                (error,,,, poolCost,,) = params.tokenToNFTTradesSpecific[i].swapInfo.pool.getBuyNFTQuote(
                    params.tokenToNFTTradesSpecific[i].swapInfo.nftIds.length
                );

                // If within our maxCost and no error, proceed
                if (poolCost <= params.tokenToNFTTradesSpecific[i].maxCost && error == CurveErrorCodes.Error.OK) {
                    // We know how much ETH to send because we already did the math above
                    // So we just send that much
                    if (params.tokenToNFTTradesSpecific[i].isETHSwap) {
                        remainingETHValue -= params.tokenToNFTTradesSpecific[i].swapInfo.pool.swapTokenForSpecificNFTs{
                            value: poolCost
                        }(params.tokenToNFTTradesSpecific[i].swapInfo.nftIds, poolCost, msg.sender, true, msg.sender);
                    }
                    // Otherwise we send ERC20 tokens
                    else {
                        params.tokenToNFTTradesSpecific[i].swapInfo.pool.swapTokenForSpecificNFTs(
                            params.tokenToNFTTradesSpecific[i].swapInfo.nftIds, poolCost, msg.sender, true, msg.sender
                        );
                    }
                }

                unchecked {
                    ++i;
                }
            }
            // Return remaining value to sender
            if (remainingETHValue > 0) {
                payable(msg.sender).safeTransferETH(remainingETHValue);
            }
        }
        // Attempt to fill each sell order
        {
            uint256 numSwaps = params.nftToTokenTrades.length;
            for (uint256 i; i < numSwaps;) {
                uint256 poolOutput;

                // Locally scoped to avoid stack too deep error
                {
                    CurveErrorCodes.Error error;
                    (error,,,, poolOutput,,) = params.nftToTokenTrades[i].swapInfo.pool.getSellNFTQuote(
                        params.nftToTokenTrades[i].swapInfo.nftIds.length
                    );
                    if (error != CurveErrorCodes.Error.OK) {
                        unchecked {
                            ++i;
                        }
                        continue;
                    }
                }

                // If at least equal to our minOutput, proceed
                if (poolOutput >= params.nftToTokenTrades[i].minOutput) {
                    // Do the swap
                    params.nftToTokenTrades[i].swapInfo.pool.swapNFTsForToken(
                        ICollectionPool.NFTs(
                            params.nftToTokenTrades[i].swapInfo.nftIds,
                            params.nftToTokenTrades[i].swapInfo.proof,
                            params.nftToTokenTrades[i].swapInfo.proofFlags,
                            params.nftToTokenTrades[i].swapInfo.proofLeaves
                        ),
                        0,
                        payable(msg.sender),
                        true,
                        msg.sender
                    );
                }

                unchecked {
                    ++i;
                }
            }
        }
    }

    receive() external payable {}

    /**
     * Restricted functions
     */

    /**
     * @dev Allows an ERC20 pool contract to transfer ERC20 tokens directly from
     * the sender, in order to minimize the number of token transfers. Only callable by an ERC20 pool.
     * @param token The ERC20 token to transfer
     * @param from The address to transfer tokens from
     * @param to The address to transfer tokens to
     * @param amount The amount of tokens to transfer
     * @param variant The pool variant of the pool contract
     */
    function poolTransferERC20From(ERC20 token, address from, address to, uint256 amount, uint8 variant) external {
        // verify caller is an ERC20 pool contract
        ICollectionPoolFactory.PoolVariant _variant = ICollectionPoolFactory.PoolVariant(variant);
        require(erc721factory.isPool(msg.sender, _variant), "Not pool");

        // verify caller is an ERC20 pool
        require(
            _variant == ICollectionPoolFactory.PoolVariant.ENUMERABLE_ERC20
                || _variant == ICollectionPoolFactory.PoolVariant.MISSING_ENUMERABLE_ERC20,
            "Not ERC20 pool"
        );
        // transfer tokens to pool
        token.safeTransferFrom(from, to, amount);
    }

    /**
     * @dev Allows a pool contract to transfer ERC721 NFTs directly from
     * the sender, in order to minimize the number of token transfers. Only callable by a pool.
     * @param nft The ERC721 NFT to transfer
     * @param from The address to transfer tokens from
     * @param to The address to transfer tokens to
     * @param id The ID of the NFT to transfer
     * @param variant The pool variant of the pool contract
     */
    function poolTransferNFTFrom(
        IERC721 nft,
        address from,
        address to,
        uint256 id,
        ICollectionPoolFactory.PoolVariant variant
    ) external {
        // verify caller is a trusted pool contract
        require(erc721factory.isPool(msg.sender, variant), "Not pool");
        // transfer NFTs to pool
        nft.safeTransferFrom(from, to, id);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {ICurve} from "../bonding-curves/ICurve.sol";
import {CurveErrorCodes} from "../bonding-curves/CurveErrorCodes.sol";
import {ITokenIDFilter} from "../filter/ITokenIDFilter.sol";

interface ICollectionPool is ITokenIDFilter {
    enum PoolType {
        TOKEN,
        NFT,
        TRADE
    }

    /**
     * @param ids The list of IDs of the NFTs to sell to the pool
     * @param proof Merkle multiproof proving list is allowed by pool
     * @param proofFlags Merkle multiproof flags for proof
     * @param proofLeaves Sorted leaves of Merkle multiproof
     */
    struct NFTs {
        uint256[] ids;
        bytes32[] proof;
        bool[] proofFlags;
        bytes32[] proofLeaves;
    }

    function bondingCurve() external view returns (ICurve);

    function getAllHeldIds() external view returns (uint256[] memory);

    function delta() external view returns (uint128);

    function fee() external view returns (uint96);

    function nft() external view returns (IERC721);

    function poolType() external view returns (PoolType);

    function spotPrice() external view returns (uint128);

    function royaltyNumerator() external view returns (uint256);

    /**
     * @notice Rescues a specified set of NFTs owned by the pool to the owner address. (onlyOwnable modifier is in the implemented function)
     * @dev If the NFT is the pool's collection, we also remove it from the id tracking (if the NFT is missing enumerable).
     * @param a The NFT to transfer
     * @param nftIds The list of IDs of the NFTs to send to the owner
     */
    function withdrawERC721(IERC721 a, uint256[] calldata nftIds) external;

    /**
     * @notice Rescues ERC20 tokens from the pool to the owner. Only callable by the owner (onlyOwnable modifier is in the implemented function).
     * @param a The token to transfer
     * @param amount The amount of tokens to send to the owner
     */
    function withdrawERC20(ERC20 a, uint256 amount) external;

    function withdrawERC1155(IERC1155 a, uint256[] calldata ids, uint256[] calldata amounts) external;

    function getSellNFTQuote(uint256 numNFTs)
        external
        view
        returns (
            CurveErrorCodes.Error error,
            uint256 newSpotPrice,
            uint256 newDelta,
            bytes memory newState,
            uint256 outputAmount,
            uint256 tradeFee,
            uint256 protocolFee
        );
}

interface ICollectionPoolETH is ICollectionPool {
    function withdrawAllETH() external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import {ReentrancyGuard} from "../lib/ReentrancyGuard.sol";
import {ICurve} from "../bonding-curves/ICurve.sol";
import {CollectionRouter} from "../routers/CollectionRouter.sol";
import {ICollectionPool} from "./ICollectionPool.sol";
import {ICollectionPoolFactory} from "./ICollectionPoolFactory.sol";
import {CurveErrorCodes} from "../bonding-curves/CurveErrorCodes.sol";
import {TokenIDFilter} from "../filter/TokenIDFilter.sol";
import {ERC1155Holder} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

/// @title The base contract for an NFT/TOKEN AMM pool
/// @author Collection
/// @notice This implements the core swap logic from NFT to TOKEN
abstract contract CollectionPool is ReentrancyGuard, ERC1155Holder, TokenIDFilter, ICollectionPool {
    /**
     * @dev The RoyaltyDue struct is used to track information about royalty payments that are due on NFT swaps.
     * It contains two fields:
     * @dev amount: The amount of the royalty payment, in the token's base units.
     * This value is calculated based on the price of the NFT being swapped, and the royaltyNumerator value set in the AMM pool contract.
     * @dev recipient: The address to which the royalty payment should be sent.
     * This value is determined by the NFT being swapped, and it is specified in the ERC2981 metadata for the NFT.
     * @dev When a user swaps an NFT for tokens using the AMM pool contract, a RoyaltyDue struct is created to track the amount
     * and recipient of the royalty payment that is due on the NFT swap. This struct is then used to facilitate the payment of
     * the royalty to the appropriate recipient.
     */
    struct RoyaltyDue {
        uint256 amount;
        address recipient;
    }

    /**
     * @dev The _INTERFACE_ID_ERC2981 constant specifies the interface ID for the ERC2981 standard. This standard is used for tracking
     * royalties on non-fungible tokens (NFTs). It defines a standard interface for NFTs that includes metadata about the royalties that
     * are due on the NFT when it is swapped or transferred.
     * @dev The _INTERFACE_ID_ERC2981 constant is used in the AMM pool contract to check whether an NFT being swapped implements the ERC2981
     * standard. If it does, the contract can use the metadata provided by the ERC2981 interface to facilitate the payment of royalties on the
     * NFT swap. If the NFT does not implement the ERC2981 standard, the contract will not track or pay royalties on the NFT swap.
     * This can be overridden by the royaltyNumerator field in the AMM pool contract.
     * @dev For more information about the ERC2981 standard, see https://eips.ethereum.org/EIPS/eip-2981
     */
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    /**
     * @dev The MAX_FEE constant specifies the maximum fee you, the user, are allowed to charge for this AMM pool.
     * It is used to limit the amount of fees that can be charged by the AMM pool contract on NFT/token swaps.
     * @dev The MAX_FEE constant is used to ensure that the AMM pool does not charge excessive fees on NFT/token swaps.
     * It also helps to protect users from paying excessive fees when using the AMM pool contract.
     * @dev usage: 90%, must <= 1 - MAX_PROTOCOL_FEE (set in CollectionPoolFactory)
     * @dev If the bid/ask is 9/10 and the fee is set to 1%, then the fee is calculated as follows:
     * @dev For a buy order, the fee would be the bid price multiplied by the fee rate, or 9 * 1% = 0.09
     * @dev For a sell order, the fee would be the ask price multiplied by the fee rate, or 10 * 1% = 0.1
     * @dev The fee is charged as a percentage of the bid/ask price, and it is used to cover the costs associated with running the AMM pool
     * contract and providing liquidity to the decentralized exchange. The fee is deducted from the final price of the token or NFT swap,
     * and it is paid to the contract owner or to a designated fee recipient. The exact fee rate and fee recipient can be configured by the
     * contract owner when the AMM pool contract is deployed.
     */
    uint256 internal constant MAX_FEE = 0.9e18;

    // The current price of the NFT
    // @dev This is generally used to mean the immediate sell price for the next marginal NFT.
    // However, this should NOT be assumed, as future bonding curves may use spotPrice in different ways.
    // Use getBuyNFTQuote and getSellNFTQuote for accurate pricing info.
    uint128 public spotPrice;

    // The parameter for the pool's bonding curve.
    // Units and meaning are bonding curve dependent.
    uint128 public delta;

    // The spread between buy and sell prices, set to be a multiplier we apply to the buy price
    // Fee is only relevant for TRADE pools
    // Units are in base 1e18
    uint96 public fee;

    // If set to 0, NFTs/tokens sent by traders during trades will be sent to the pool.
    // Otherwise, assets will be sent to the set address. Not available for TRADE pools.
    address payable public assetRecipient;

    // The trade fee accrued from trades.
    uint256 public tradeFee;

    // The properties used by the pool's bonding curve.
    bytes public props;

    // The state used by the pool's bonding curve.
    bytes public state;

    // For every NFT swapped, a fraction of the cost will be sent to the
    // ERC2981 payable address for the NFT swapped. The fraction is equal to
    // `royaltyNumerator / 1e18`
    uint256 public royaltyNumerator;

    // An address to which all royalties will be paid to if not address(0). This
    // overrides ERC2981 royalties set by the NFT creator, and allows sending
    // royalties to arbitrary addresses even if a collection does not support ERC2981.
    address payable public royaltyRecipientOverride;
    // token ID assigned to the pool instance
    uint256 public tokenId;

    // creation timestamp, to prevent trades in the same time / block as pool creation
    uint256 private creationTimestamp;

    // Events
    event SwapNFTInPool();
    event SwapNFTOutPool();
    event SpotPriceUpdate(uint128 newSpotPrice);
    event TokenDeposit(uint256 amount);
    event TokenWithdrawal(uint256 amount);
    event NFTWithdrawal();
    event DeltaUpdate(uint128 newDelta);
    event FeeUpdate(uint96 newFee);
    event AssetRecipientChange(address a);
    event PropsUpdate(bytes newProps);
    event StateUpdate(bytes newState);
    event RoyaltyNumeratorUpdate(uint256 newRoyaltyNumerator);
    event RoyaltyRecipientOverrideUpdate(address payable newOverride);

    // Parameterized Errors
    error BondingCurveError(CurveErrorCodes.Error error);

    /**
     * @dev Use this whenever modifying the value of royaltyNumerator.
     */
    modifier validRoyaltyNumerator(uint256 _royaltyNumerator) {
        require(_royaltyNumerator < 1e18, "royaltyNumerator must be < 1e18");
        _;
    }

    /**
     * Ownable functions
     */

    /// @dev Returns the address of the current owner.
    function owner() public view virtual returns (address) {
        return IERC721(address(factory())).ownerOf(tokenId);
    }

    /// @dev Throws if called by any account other than the owner.
    modifier onlyOwner() {
        require(msg.sender == owner(), "not authorized");
        _;
    }

    /// @dev Throws if called by accounts that were not authorized by the owner.
    modifier onlyAuthorized() {
        factory().requireAuthorizedForToken(msg.sender, tokenId);
        _;
    }

    /// @dev Transfers ownership of the contract to a new account (`newOwner`).
    /// Disallows setting to the zero address as a way to more gas-efficiently avoid reinitialization
    /// When ownership is transferred, if the new owner implements IOwnershipTransferCallback, we make a callback
    /// Can only be called by the current owner.
    function transferOwnership(address newOwner) public virtual onlyOwner {
        IERC721(address(factory())).safeTransferFrom(msg.sender, newOwner, tokenId);
    }

    /**
     * @notice Called during pool creation to set initial parameters
     * @dev Only called once by factory to initialize.
     * We verify this by making sure that the current owner is address(0).
     * The Ownable library we use disallows setting the owner to be address(0), so this condition
     * should only be valid before the first initialize call.
     * @param _tokenId The token id of the pool
     * @param _assetRecipient The address that will receive the TOKEN or NFT sent to this pool during swaps.
     * NOTE: If set to address(0), they will go to the pool itself.
     * @param _delta The initial delta of the bonding curve
     * @param _fee The initial % fee taken, if this is a trade pool
     * @param _spotPrice The initial price to sell an asset into the pool
     * @param _royaltyNumerator All trades will result in `royaltyNumerator` * <trade amount> / 1e18
     * being sent to the account to which the traded NFT's royalties are awardable.
     * Must be 0 if `_nft` is not IERC2981 and no recipient override is set.
     * @param _royaltyRecipientOverride An address to which all royalties will
     * be paid to if not address(0). This overrides ERC2981 royalties set by
     * the NFT creator, and allows sending royalties to arbitrary addresses
     * even if a collection does not support ERC2981.
     */
    function initialize(
        uint256 _tokenId,
        address payable _assetRecipient,
        uint128 _delta,
        uint96 _fee,
        uint128 _spotPrice,
        bytes calldata _props,
        bytes calldata _state,
        uint256 _royaltyNumerator,
        address payable _royaltyRecipientOverride
    ) external payable validRoyaltyNumerator(_royaltyNumerator) {
        require(tokenId == 0, "Initialized");
        tokenId = _tokenId;
        creationTimestamp = block.timestamp;
        __ReentrancyGuard_init();

        ICurve _bondingCurve = bondingCurve();
        PoolType _poolType = poolType();

        if ((_poolType == PoolType.TOKEN) || (_poolType == PoolType.NFT)) {
            require(_fee == 0, "Only Trade Pools can have nonzero fee");
            assetRecipient = _assetRecipient;
        } else if (_poolType == PoolType.TRADE) {
            require(_fee < MAX_FEE, "Trade fee must be less than 90%");
            require(_assetRecipient == address(0), "Trade pools can't set asset recipient");
            fee = _fee;
        }
        require(_bondingCurve.validateDelta(_delta), "Invalid delta for curve");
        require(_bondingCurve.validateSpotPrice(_spotPrice), "Invalid new spot price for curve");
        require(_bondingCurve.validateProps(_props), "Invalid props for curve");
        require(_bondingCurve.validateState(_state), "Invalid state for curve");
        delta = _delta;
        spotPrice = _spotPrice;
        props = _props;
        state = _state;
        royaltyNumerator = _royaltyNumerator;
        royaltyRecipientOverride = _royaltyRecipientOverride;
    }

    /**
     * External state-changing functions
     */

    /**
     * @notice Sets NFT token ID filter that is allowed in this pool
     * @param merkleRoot Merkle root representing all allowed IDs
     * @param encodedTokenIDs Opaque encoded list of token IDs
     */
    function setTokenIDFilter(bytes32 merkleRoot, bytes calldata encodedTokenIDs) external {
        require(msg.sender == address(factory()) || msg.sender == owner(), "not authorized");
        _setRootAndEmitAcceptedIDs(address(nft()), merkleRoot, encodedTokenIDs);
    }

    /**
     * @notice Sends token to the pool in exchange for any `numNFTs` NFTs
     * @dev To compute the amount of token to send, call bondingCurve.getBuyInfo.
     * This swap function is meant for users who are ID agnostic
     * @param numNFTs The number of NFTs to purchase
     * @param maxExpectedTokenInput The maximum acceptable cost from the sender. If the actual
     * amount is greater than this value, the transaction will be reverted.
     * @param nftRecipient The recipient of the NFTs
     * @param isRouter True if calling from CollectionRouter, false otherwise. Not used for
     * ETH pools.
     * @param routerCaller If isRouter is true, ERC20 tokens will be transferred from this address. Not used for
     * ETH pools.
     * @return inputAmount The amount of token used for purchase
     */
    function swapTokenForAnyNFTs(
        uint256 numNFTs,
        uint256 maxExpectedTokenInput,
        address nftRecipient,
        bool isRouter,
        address routerCaller
    ) external payable virtual nonReentrant returns (uint256 inputAmount) {
        // Store locally to remove extra calls
        ICollectionPoolFactory _factory = factory();
        ICurve _bondingCurve = bondingCurve();
        IERC721 _nft = nft();

        // Input validation
        {
            PoolType _poolType = poolType();
            require(_poolType == PoolType.NFT || _poolType == PoolType.TRADE, "Wrong Pool type");
            require((numNFTs > 0) && (numNFTs <= _nft.balanceOf(address(this))), "Ask for > 0 and <= balanceOf NFTs");
        }

        require(creationTimestamp != block.timestamp, "Trade blocked");

        // Call bonding curve for pricing information
        ICurve.Fees memory fees;
        (inputAmount, fees) =
            _calculateBuyInfoAndUpdatePoolParams(numNFTs, maxExpectedTokenInput, _bondingCurve, _factory);

        tradeFee += fees.trade;
        uint256[] memory tokenIds = _selectArbitraryNFTs(_nft, numNFTs);
        RoyaltyDue[] memory royaltiesDue = _getRoyaltiesDue(_nft, tokenIds, fees.royalties);

        _pullTokenInputAndPayProtocolFee(inputAmount, isRouter, routerCaller, _factory, fees.protocol, royaltiesDue);

        _sendSpecificNFTsToRecipient(_nft, nftRecipient, tokenIds);

        _refundTokenToSender(inputAmount);

        emit SwapNFTOutPool();
    }

    /**
     * @notice Sends token to the pool in exchange for a specific set of NFTs
     * @dev To compute the amount of token to send, call bondingCurve.getBuyInfo
     * This swap is meant for users who want specific IDs. Also higher chance of
     * reverting if some of the specified IDs leave the pool before the swap goes through.
     * @param nftIds The list of IDs of the NFTs to purchase
     * @param maxExpectedTokenInput The maximum acceptable cost from the sender. If the actual
     * amount is greater than this value, the transaction will be reverted.
     * @param nftRecipient The recipient of the NFTs
     * @param isRouter True if calling from CollectionRouter, false otherwise. Not used for
     * ETH pools.
     * @param routerCaller If isRouter is true, ERC20 tokens will be transferred from this address. Not used for
     * ETH pools.
     * @return inputAmount The amount of token used for purchase
     */
    function swapTokenForSpecificNFTs(
        uint256[] calldata nftIds,
        uint256 maxExpectedTokenInput,
        address nftRecipient,
        bool isRouter,
        address routerCaller
    ) external payable virtual nonReentrant returns (uint256 inputAmount) {
        // Store locally to remove extra calls
        ICollectionPoolFactory _factory = factory();
        ICurve _bondingCurve = bondingCurve();

        // Input validation
        {
            PoolType _poolType = poolType();
            require(_poolType == PoolType.NFT || _poolType == PoolType.TRADE, "Wrong Pool type");
            require((nftIds.length > 0), "Must ask for > 0 NFTs");
        }

        require(creationTimestamp != block.timestamp, "Trade blocked");

        // Call bonding curve for pricing information
        ICurve.Fees memory fees;
        (inputAmount, fees) =
            _calculateBuyInfoAndUpdatePoolParams(nftIds.length, maxExpectedTokenInput, _bondingCurve, _factory);

        tradeFee += fees.trade;
        RoyaltyDue[] memory royaltiesDue = _getRoyaltiesDue(nft(), nftIds, fees.royalties);

        _pullTokenInputAndPayProtocolFee(inputAmount, isRouter, routerCaller, _factory, fees.protocol, royaltiesDue);

        _sendSpecificNFTsToRecipient(nft(), nftRecipient, nftIds);

        _refundTokenToSender(inputAmount);

        emit SwapNFTOutPool();
    }

    /**
     * @notice Sends a set of NFTs to the pool in exchange for token
     * @dev To compute the amount of token to that will be received, call bondingCurve.getSellInfo.
     * @param nfts The list of IDs of the NFTs to sell to the pool along with its Merkle multiproof.
     * @param minExpectedTokenOutput The minimum acceptable token received by the sender. If the actual
     * amount is less than this value, the transaction will be reverted.
     * @param tokenRecipient The recipient of the token output
     * @param isRouter True if calling from CollectionRouter, false otherwise. Not used for
     * ETH pools.
     * @param routerCaller If isRouter is true, ERC20 tokens will be transferred from this address. Not used for
     * ETH pools.
     * @return outputAmount The amount of token received
     */
    function swapNFTsForToken(
        ICollectionPool.NFTs calldata nfts,
        uint256 minExpectedTokenOutput,
        address payable tokenRecipient,
        bool isRouter,
        address routerCaller
    ) external virtual nonReentrant returns (uint256 outputAmount) {
        // Store locally to remove extra calls
        ICollectionPoolFactory _factory = factory();
        ICurve _bondingCurve = bondingCurve();

        // Input validation
        {
            PoolType _poolType = poolType();
            require(_poolType == PoolType.TOKEN || _poolType == PoolType.TRADE, "Wrong Pool type");
            require(nfts.ids.length > 0, "Must ask for > 0 NFTs");
            require(acceptsTokenIDs(nfts.proof, nfts.proofFlags, nfts.proofLeaves), "NFT not allowed");
        }

        // Call bonding curve for pricing information
        ICurve.Fees memory fees;
        (outputAmount, fees) =
            _calculateSellInfoAndUpdatePoolParams(nfts.ids.length, minExpectedTokenOutput, _bondingCurve);

        // Accrue trade fees before sending token output. This ensures that the balance is always sufficient for trade fee withdrawal.
        tradeFee += fees.trade;

        RoyaltyDue[] memory royaltiesDue = _getRoyaltiesDue(nft(), nfts.ids, fees.royalties);

        _sendTokenOutput(tokenRecipient, outputAmount, royaltiesDue);

        _payProtocolFeeFromPool(_factory, fees.protocol);

        _takeNFTsFromSender(nft(), nfts.ids, _factory, isRouter, routerCaller);

        emit SwapNFTInPool();
    }

    /**
     * View functions
     */

    /**
     * @notice Checks if NFTs is allowed in this pool
     * @param tokenID NFT ID
     * @param proof Merkle proof
     */
    function acceptsTokenID(uint256 tokenID, bytes32[] calldata proof) public view returns (bool) {
        return _acceptsTokenID(tokenID, proof);
    }

    /**
     * @notice Checks if list of NFTs are allowed in this pool using Merkle multiproof and flags
     * @param proof Merkle multiproof
     * @param proofFlags Merkle multiproof flags
     * @param leaves The leaves of the merkle tree in sorted order
     */
    function acceptsTokenIDs(bytes32[] calldata proof, bool[] calldata proofFlags, bytes32[] calldata leaves)
        public
        view
        returns (bool)
    {
        return _acceptsTokenIDs(proof, proofFlags, leaves);
    }

    /**
     * @dev Used as read function to query the bonding curve for buy pricing info
     * @param numNFTs The number of NFTs to buy from the pool
     */
    function getBuyNFTQuote(uint256 numNFTs)
        external
        view
        returns (
            CurveErrorCodes.Error error,
            uint256 newSpotPrice,
            uint256 newDelta,
            bytes memory newState,
            uint256 inputAmount,
            uint256 _tradeFee,
            uint256 protocolFee
        )
    {
        ICurve.Params memory newParams;
        ICurve.Fees memory fees;
        (error, newParams, inputAmount, fees) = bondingCurve().getBuyInfo(curveParams(), numNFTs, feeMultipliers());

        newSpotPrice = newParams.spotPrice;
        newDelta = newParams.delta;
        newState = newParams.state;

        _tradeFee = fees.trade;
        protocolFee = fees.protocol;
    }

    /**
     * @dev Used as read function to query the bonding curve for sell pricing info
     * @param numNFTs The number of NFTs to sell to the pool
     */
    function getSellNFTQuote(uint256 numNFTs)
        external
        view
        returns (
            CurveErrorCodes.Error error,
            uint256 newSpotPrice,
            uint256 newDelta,
            bytes memory newState,
            uint256 outputAmount,
            uint256 _tradeFee,
            uint256 protocolFee
        )
    {
        ICurve.Params memory newParams;
        ICurve.Fees memory fees;
        (error, newParams, outputAmount, fees) = bondingCurve().getSellInfo(curveParams(), numNFTs, feeMultipliers());

        newSpotPrice = newParams.spotPrice;
        newDelta = newParams.delta;
        newState = newParams.state;

        _tradeFee = fees.trade;
        protocolFee = fees.protocol;
    }

    /**
     * @notice Returns all NFT IDs held by the pool
     */
    function getAllHeldIds() external view virtual returns (uint256[] memory);

    /**
     * @notice Returns the pool's variant (NFT is enumerable or not, pool uses ETH or ERC20)
     */
    function poolVariant() public pure virtual returns (ICollectionPoolFactory.PoolVariant);

    function factory() public pure returns (ICollectionPoolFactory _factory) {
        uint256 paramsLength = _immutableParamsLength();
        assembly {
            _factory := shr(0x60, calldataload(sub(calldatasize(), paramsLength)))
        }
    }

    /**
     * @notice Returns the type of bonding curve that parameterizes the pool
     */
    function bondingCurve() public pure returns (ICurve _bondingCurve) {
        uint256 paramsLength = _immutableParamsLength();
        assembly {
            _bondingCurve := shr(0x60, calldataload(add(sub(calldatasize(), paramsLength), 20)))
        }
    }

    /**
     * @notice Returns the NFT collection that parameterizes the pool
     */
    function nft() public pure returns (IERC721 _nft) {
        uint256 paramsLength = _immutableParamsLength();
        assembly {
            _nft := shr(0x60, calldataload(add(sub(calldatasize(), paramsLength), 40)))
        }
    }

    /**
     * @notice Returns the pool's type (TOKEN/NFT/TRADE)
     */
    function poolType() public pure returns (PoolType _poolType) {
        uint256 paramsLength = _immutableParamsLength();
        assembly {
            _poolType := shr(0xf8, calldataload(add(sub(calldatasize(), paramsLength), 60)))
        }
    }

    /**
     * @notice Handles royalty recipient and fallback logic. Attempts to honor
     * ERC2981 where possible, followed by the owner's set fallback. If neither
     * is a valid address, then royalties go to the asset recipient for this
     * pool.
     * @param erc2981Recipient The address to which royalties should be paid as
     * returned by the IERC2981 `royaltyInfo` method. `payable(address(0))` if
     * the nft does not implement IERC2981.
     * @return The address to which royalties should be paid
     */
    function getRoyaltyRecipient(address payable erc2981Recipient) internal view returns (address payable) {
        if (erc2981Recipient != address(0)) {
            return erc2981Recipient;
        }

        // No recipient from ERC2981 royaltyInfo method. Check if we have a fallback
        if (royaltyRecipientOverride != address(0)) {
            return royaltyRecipientOverride;
        }

        // No ERC2981 recipient or recipient fallback. Default to pool.
        return getAssetRecipient();
    }

    /**
     * @notice Returns the address that assets that receives assets when a swap is done with this pool
     * Can be set to another address by the owner, if set to address(0), defaults to the pool's own address
     */
    function getAssetRecipient() public view returns (address payable _assetRecipient) {
        // If it's a TRADE pool, we know the recipient is 0 (TRADE pools can't set asset recipients)
        // so just return address(this)
        if (poolType() == PoolType.TRADE) {
            return payable(address(this));
        }

        // Otherwise, we return the recipient if it's been set
        // or replace it with address(this) if it's 0
        _assetRecipient = assetRecipient;
        if (_assetRecipient == address(0)) {
            // Tokens will be transferred to address(this)
            _assetRecipient = payable(address(this));
        }
    }

    function curveParams() public view returns (ICurve.Params memory params) {
        return ICurve.Params(spotPrice, delta, props, state);
    }

    function feeMultipliers() public view returns (ICurve.FeeMultipliers memory) {
        uint256 protocolFeeMultiplier;
        uint256 carryFeeMultiplier;

        PoolType _poolType = poolType();
        if ((_poolType == PoolType.TOKEN) || (_poolType == PoolType.NFT)) {
            protocolFeeMultiplier = factory().protocolFeeMultiplier();
        } else if (_poolType == PoolType.TRADE) {
            carryFeeMultiplier = factory().carryFeeMultiplier();
        }

        return ICurve.FeeMultipliers(fee, protocolFeeMultiplier, royaltyNumerator, carryFeeMultiplier);
    }

    /**
     * Internal functions
     */

    /**
     * @notice Calculates the amount needed to be sent into the pool for a buy and adjusts spot price or delta if necessary
     * @param numNFTs The amount of NFTs to purchase from the pool
     * @param maxExpectedTokenInput The maximum acceptable cost from the sender. If the actual
     * amount is greater than this value, the transaction will be reverted.
     * @return inputAmount The amount of tokens total tokens receive
     * @return fees The amount of tokens to send as fees
     */
    function _calculateBuyInfoAndUpdatePoolParams(
        uint256 numNFTs,
        uint256 maxExpectedTokenInput,
        ICurve _bondingCurve,
        ICollectionPoolFactory
    ) internal returns (uint256 inputAmount, ICurve.Fees memory fees) {
        CurveErrorCodes.Error error;
        ICurve.Params memory params = curveParams();
        ICurve.Params memory newParams;
        (error, newParams, inputAmount, fees) = _bondingCurve.getBuyInfo(params, numNFTs, feeMultipliers());

        // Revert if bonding curve had an error
        if (error != CurveErrorCodes.Error.OK) {
            revert BondingCurveError(error);
        }

        // Revert if input is more than expected
        require(inputAmount <= maxExpectedTokenInput, "In too many tokens");

        // Consolidate writes to save gas
        if (params.spotPrice != newParams.spotPrice || params.delta != newParams.delta) {
            spotPrice = newParams.spotPrice;
            delta = newParams.delta;
        }

        if (keccak256(params.state) != keccak256(newParams.state)) {
            state = newParams.state;

            emit StateUpdate(newParams.state);
        }

        // Emit spot price update if it has been updated
        if (params.spotPrice != newParams.spotPrice) {
            emit SpotPriceUpdate(newParams.spotPrice);
        }

        // Emit delta update if it has been updated
        if (params.delta != newParams.delta) {
            emit DeltaUpdate(newParams.delta);
        }
    }

    /**
     * @notice Calculates the amount needed to be sent by the pool for a sell and adjusts spot price or delta if necessary
     * @param numNFTs The amount of NFTs to send to the the pool
     * @param minExpectedTokenOutput The minimum acceptable token received by the sender. If the actual
     * amount is less than this value, the transaction will be reverted.
     * @param _bondingCurve The bonding curve used to fetch pricing information from
     * @return outputAmount The amount of tokens total tokens receive
     * @return fees The amount of tokens to send as fees
     */
    function _calculateSellInfoAndUpdatePoolParams(
        uint256 numNFTs,
        uint256 minExpectedTokenOutput,
        ICurve _bondingCurve
    ) internal returns (uint256 outputAmount, ICurve.Fees memory fees) {
        CurveErrorCodes.Error error;
        ICurve.Params memory params = curveParams();
        ICurve.Params memory newParams;
        (error, newParams, outputAmount, fees) = _bondingCurve.getSellInfo(params, numNFTs, feeMultipliers());

        // Revert if bonding curve had an error
        if (error != CurveErrorCodes.Error.OK) {
            revert BondingCurveError(error);
        }

        // Revert if output is too little
        require(outputAmount >= minExpectedTokenOutput, "Out too little tokens");

        // Consolidate writes to save gas
        if (params.spotPrice != newParams.spotPrice || params.delta != newParams.delta) {
            spotPrice = newParams.spotPrice;
            delta = newParams.delta;
        }

        if (keccak256(params.state) != keccak256(newParams.state)) {
            state = newParams.state;

            emit StateUpdate(newParams.state);
        }

        // Emit spot price update if it has been updated
        if (params.spotPrice != newParams.spotPrice) {
            emit SpotPriceUpdate(newParams.spotPrice);
        }

        // Emit delta update if it has been updated
        if (params.delta != newParams.delta) {
            emit DeltaUpdate(newParams.delta);
        }
    }

    /**
     * @notice Pulls the token input of a trade from the trader and pays the protocol fee.
     * @param inputAmount The amount of tokens to be sent
     * @param isRouter Whether or not the caller is CollectionRouter
     * @param routerCaller If called from CollectionRouter, store the original caller
     * @param _factory The CollectionPoolFactory which stores CollectionRouter allowlist info
     * @param protocolFee The protocol fee to be paid
     * @param royaltyAmounts An array of royalties to pay
     */
    function _pullTokenInputAndPayProtocolFee(
        uint256 inputAmount,
        bool isRouter,
        address routerCaller,
        ICollectionPoolFactory _factory,
        uint256 protocolFee,
        RoyaltyDue[] memory royaltyAmounts
    ) internal virtual;

    /**
     * @notice Sends excess tokens back to the caller (if applicable)
     * @dev We send ETH back to the caller even when called from CollectionRouter because we do an aggregate slippage check for certain bulk swaps. (Instead of sending directly back to the router caller)
     * Excess ETH sent for one swap can then be used to help pay for the next swap.
     */
    function _refundTokenToSender(uint256 inputAmount) internal virtual;

    /**
     * @notice Sends protocol fee (if it exists) back to the CollectionPoolFactory from the pool
     */
    function _payProtocolFeeFromPool(ICollectionPoolFactory _factory, uint256 protocolFee) internal virtual;

    /**
     * @notice Sends tokens to a recipient and pays royalties owed
     * @param tokenRecipient The address receiving the tokens
     * @param outputAmount The amount of tokens to send
     * @param royaltiesDue An array of royalties to pay
     */
    function _sendTokenOutput(address payable tokenRecipient, uint256 outputAmount, RoyaltyDue[] memory royaltiesDue)
        internal
        virtual;

    /**
     * @notice Select arbitrary NFTs from pool
     * @param _nft The address of the NFT to send
     * @param numNFTs The number of NFTs to send
     */
    function _selectArbitraryNFTs(IERC721 _nft, uint256 numNFTs) internal virtual returns (uint256[] memory tokenIds);

    /**
     * @notice Sends specific NFTs to a recipient address
     * @dev Even though we specify the NFT address here, this internal function is only
     * used to send NFTs associated with this specific pool.
     * @param _nft The address of the NFT to send
     * @param nftRecipient The receiving address for the NFTs
     * @param nftIds The specific IDs of NFTs to send
     */
    function _sendSpecificNFTsToRecipient(IERC721 _nft, address nftRecipient, uint256[] memory nftIds)
        internal
        virtual;

    /**
     * @notice Takes NFTs from the caller and sends them into the pool's asset recipient
     * @dev This is used by the CollectionPool's swapNFTForToken function.
     * @param _nft The NFT collection to take from
     * @param nftIds The specific NFT IDs to take
     * @param isRouter True if calling from CollectionRouter, false otherwise. Not used for
     * ETH pools.
     * @param routerCaller If isRouter is true, ERC20 tokens will be transferred from this address. Not used for
     * ETH pools.
     */
    function _takeNFTsFromSender(
        IERC721 _nft,
        uint256[] calldata nftIds,
        ICollectionPoolFactory _factory,
        bool isRouter,
        address routerCaller
    ) internal virtual {
        {
            address _assetRecipient = getAssetRecipient();
            uint256 numNFTs = nftIds.length;

            if (isRouter) {
                // Verify if router is allowed
                CollectionRouter router = CollectionRouter(payable(msg.sender));
                (bool routerAllowed,) = _factory.routerStatus(router);
                require(routerAllowed, "Not router");

                // Call router to pull NFTs
                // If more than 1 NFT is being transfered, we can do a balance check instead of an ownership check, as pools are indifferent between NFTs from the same collection
                if (numNFTs > 1) {
                    uint256 beforeBalance = _nft.balanceOf(_assetRecipient);
                    for (uint256 i = 0; i < numNFTs;) {
                        router.poolTransferNFTFrom(_nft, routerCaller, _assetRecipient, nftIds[i], poolVariant());

                        unchecked {
                            ++i;
                        }
                    }
                    require((_nft.balanceOf(_assetRecipient) - beforeBalance) == numNFTs, "NFTs not transferred");
                } else {
                    router.poolTransferNFTFrom(_nft, routerCaller, _assetRecipient, nftIds[0], poolVariant());
                    require(_nft.ownerOf(nftIds[0]) == _assetRecipient, "NFT not transferred");
                }
            } else {
                // Pull NFTs directly from sender
                for (uint256 i; i < numNFTs;) {
                    _nft.safeTransferFrom(msg.sender, _assetRecipient, nftIds[i]);

                    unchecked {
                        ++i;
                    }
                }
            }
        }
    }

    /**
     * @dev Used internally to grab pool parameters from calldata, see CollectionPoolCloner for technical details
     */
    function _immutableParamsLength() internal pure virtual returns (uint256);

    /**
     * Owner functions
     */

    /**
     * @notice Rescues ERC1155 tokens from the pool to the owner. Only callable by the owner.
     * @param a The NFT to transfer
     * @param ids The NFT ids to transfer
     * @param amounts The amounts of each id to transfer
     */
    function withdrawERC1155(IERC1155 a, uint256[] calldata ids, uint256[] calldata amounts) external onlyAuthorized {
        a.safeBatchTransferFrom(address(this), owner(), ids, amounts, "");
    }

    /**
     * @notice Withdraws trade fee owned by the pool to the owner address.
     * @dev Only callable by the owner.
     */
    function withdrawTradeFee() external virtual;

    /**
     * @notice Updates the selling spot price. Only callable by the owner.
     * @param newSpotPrice The new selling spot price value, in Token
     */
    function changeSpotPrice(uint128 newSpotPrice) external onlyOwner {
        ICurve _bondingCurve = bondingCurve();
        require(_bondingCurve.validateSpotPrice(newSpotPrice), "Invalid new spot price for curve");
        if (spotPrice != newSpotPrice) {
            spotPrice = newSpotPrice;
            emit SpotPriceUpdate(newSpotPrice);
        }
    }

    /**
     * @notice Updates the delta parameter. Only callable by the owner.
     * @param newDelta The new delta parameter
     */
    function changeDelta(uint128 newDelta) external onlyOwner {
        ICurve _bondingCurve = bondingCurve();
        require(_bondingCurve.validateDelta(newDelta), "Invalid delta for curve");
        if (delta != newDelta) {
            delta = newDelta;
            emit DeltaUpdate(newDelta);
        }
    }

    /**
     * @notice Updates the props parameter. Only callable by the owner.
     * @param newProps The new props parameter
     */
    function changeProps(bytes calldata newProps) external onlyOwner {
        ICurve _bondingCurve = bondingCurve();
        require(_bondingCurve.validateProps(newProps), "Invalid props for curve");
        if (keccak256(props) != keccak256(newProps)) {
            props = newProps;
            emit PropsUpdate(newProps);
        }
    }

    /**
     * @notice Updates the state parameter. Only callable by the owner.
     * @param newState The new state parameter
     */
    function changeState(bytes calldata newState) external onlyOwner {
        ICurve _bondingCurve = bondingCurve();
        require(_bondingCurve.validateState(newState), "Invalid state for curve");
        if (keccak256(state) != keccak256(newState)) {
            state = newState;
            emit StateUpdate(newState);
        }
    }

    /**
     * @notice Updates the fee taken by the LP. Only callable by the owner.
     * Only callable if the pool is a Trade pool. Reverts if the fee is >=
     * MAX_FEE.
     * @param newFee The new LP fee percentage, 18 decimals
     */
    function changeFee(uint96 newFee) external onlyOwner {
        PoolType _poolType = poolType();
        require(_poolType == PoolType.TRADE, "Only for Trade pools");
        require(newFee < MAX_FEE, "Trade fee must be less than 90%");
        if (fee != newFee) {
            fee = newFee;
            emit FeeUpdate(newFee);
        }
    }

    /**
     * @notice Changes the address that will receive assets received from
     * trades. Only callable by the owner.
     * @param newRecipient The new asset recipient
     */
    function changeAssetRecipient(address payable newRecipient) external onlyOwner {
        PoolType _poolType = poolType();
        require(_poolType != PoolType.TRADE, "Not for Trade pools");
        if (assetRecipient != newRecipient) {
            assetRecipient = newRecipient;
            emit AssetRecipientChange(newRecipient);
        }
    }

    function changeRoyaltyNumerator(uint256 newRoyaltyNumerator)
        external
        onlyOwner
        validRoyaltyNumerator(newRoyaltyNumerator)
    {
        require(
            _validRoyaltyState(newRoyaltyNumerator, royaltyRecipientOverride, nft()),
            "Invalid royaltyNumerator or royaltyRecipientOverride"
        );
        royaltyNumerator = newRoyaltyNumerator;
        emit RoyaltyNumeratorUpdate(newRoyaltyNumerator);
    }

    function changeRoyaltyRecipientOverride(address payable newOverride) external onlyOwner {
        require(
            _validRoyaltyState(royaltyNumerator, newOverride, nft()),
            "Invalid royaltyNumerator or royaltyRecipientOverride"
        );
        royaltyRecipientOverride = newOverride;
        emit RoyaltyRecipientOverrideUpdate(newOverride);
    }

    /**
     * @notice Allows the pool to make arbitrary external calls to contracts
     * whitelisted by the protocol. Only callable by authorized parties.
     * @param target The contract to call
     * @param data The calldata to pass to the contract
     */
    function call(address payable target, bytes calldata data) external onlyAuthorized {
        ICollectionPoolFactory _factory = factory();
        require(_factory.callAllowed(target), "Target must be whitelisted");
        (bool result,) = target.call{value: 0}(data);
        require(result, "Call failed");
    }

    /**
     * @notice Allows owner to batch multiple calls, forked from: https://github.com/boringcrypto/BoringSolidity/blob/master/contracts/BoringBatchable.sol
     * @dev Intended for withdrawing/altering pool pricing in one tx, only callable by owner, cannot change owner
     * @param calls The calldata for each call to make
     * @param revertOnFail Whether or not to revert the entire tx if any of the calls fail
     */
    function multicall(bytes[] calldata calls, bool revertOnFail) external onlyAuthorized {
        for (uint256 i; i < calls.length;) {
            (bool success, bytes memory result) = address(this).delegatecall(calls[i]);
            if (!success && revertOnFail) {
                revert(_getRevertMsg(result));
            }

            unchecked {
                ++i;
            }
        }

        // Prevent multicall from malicious frontend sneaking in ownership change
        require(owner() == msg.sender, "Ownership cannot be changed in multicall");
    }

    /**
     * @param _returnData The data returned from a multicall result
     * @dev Used to grab the revert string from the underlying call
     */
    function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }

    function _getRoyaltiesDue(IERC721 _nft, uint256[] memory nftIds, uint256[] memory royaltyAmounts)
        private
        view
        returns (RoyaltyDue[] memory royaltiesDue)
    {
        uint256 length = royaltyAmounts.length;
        royaltiesDue = new RoyaltyDue[](length);
        bool is2981 = IERC165(_nft).supportsInterface(_INTERFACE_ID_ERC2981);
        if (royaltyNumerator != 0) {
            for (uint256 i = 0; i < length;) {
                // 2981 recipient, if nft is 2981 and recipient is set.
                address recipient2981;
                if (is2981) {
                    (recipient2981,) = IERC2981(address(_nft)).royaltyInfo(nftIds[i], 0);
                }

                address recipient = getRoyaltyRecipient(payable(recipient2981));
                royaltiesDue[i] = RoyaltyDue({amount: royaltyAmounts[i], recipient: recipient});

                unchecked {
                    ++i;
                }
            }
        }
    }

    /**
     * @notice Returns true if it's valid to set the contract variables to the
     * variables passed to this function.
     */
    function _validRoyaltyState(uint256 _royaltyNumerator, address payable _royaltyRecipientOverride, IERC721 _nft)
        internal
        view
        returns (bool)
    {
        return
        // Supports 2981 interface to tell us who gets royalties or
        (
            IERC165(_nft).supportsInterface(_INTERFACE_ID_ERC2981)
            // There is an override so we always know where to send royaltiers or
            || _royaltyRecipientOverride != address(0)
            // Royalties will not be paid
            || _royaltyNumerator == 0
        );
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import {CollectionRouter} from "../routers/CollectionRouter.sol";
import {ICurve} from "../bonding-curves/ICurve.sol";
import {ICollectionPool} from "../pools/ICollectionPool.sol";

interface ICollectionPoolFactory is IERC721, IERC721Enumerable {
    enum PoolVariant {
        ENUMERABLE_ETH,
        MISSING_ENUMERABLE_ETH,
        ENUMERABLE_ERC20,
        MISSING_ENUMERABLE_ERC20
    }

    struct LPTokenParams721 {
        address nftAddress;
        address bondingCurveAddress;
        address tokenAddress;
        address payable poolAddress;
        uint96 fee;
        uint128 delta;
        uint256 royaltyNumerator;
    }

    /**
     * @param merkleRoot Merkle root for NFT ID filter
     * @param encodedTokenIDs Encoded list of acceptable NFT IDs
     * @param initialProof Merkle multiproof for initial NFT IDs
     * @param initialProofFlags Merkle multiproof flags for initial NFT IDs
     * @param initialProofLeaves Sorted leaves of Merkle multiproof
     */
    struct NFTFilterParams {
        bytes32 merkleRoot;
        bytes encodedTokenIDs;
        bytes32[] initialProof;
        bool[] initialProofFlags;
        bytes32[] initialProofLeaves;
    }

    /**
     * @notice Creates a pool contract using EIP-1167.
     * @param nft The NFT contract of the collection the pool trades
     * @param bondingCurve The bonding curve for the pool to price NFTs, must be whitelisted
     * @param assetRecipient The address that will receive the assets traders give during trades.
     *                       If set to address(0), assets will be sent to the pool address.
     *                       Not available to TRADE pools.
     * @param receiver Receiver of the LP token generated to represent ownership of the pool
     * @param poolType TOKEN, NFT, or TRADE
     * @param delta The delta value used by the bonding curve. The meaning of delta depends
     * on the specific curve.
     * @param fee The fee taken by the LP in each trade. Can only be non-zero if _poolType is Trade.
     * @param spotPrice The initial selling spot price
     * @param royaltyNumerator All trades will result in `royaltyNumerator` * <trade amount> / 1e18
     * being sent to the account to which the traded NFT's royalties are awardable.
     * Must be 0 if `_nft` is not IERC2981 and no recipient override is set.
     * @param royaltyRecipientOverride An address to which all royalties will
     * be paid to if not address(0). This overrides ERC2981 royalties set by
     * the NFT creator, and allows sending royalties to arbitrary addresses
     * even if a collection does not support ERC2981.
     * @param initialNFTIDs The list of IDs of NFTs to transfer from the sender to the pool
     * @return pool The new pool
     */
    struct CreateETHPoolParams {
        IERC721 nft;
        ICurve bondingCurve;
        address payable assetRecipient;
        address receiver;
        ICollectionPool.PoolType poolType;
        uint128 delta;
        uint96 fee;
        uint128 spotPrice;
        bytes props;
        bytes state;
        uint256 royaltyNumerator;
        address payable royaltyRecipientOverride;
        uint256[] initialNFTIDs;
    }

    /**
     * @notice Creates a pool contract using EIP-1167.
     * @param token The ERC20 token used for pool swaps
     * @param nft The NFT contract of the collection the pool trades
     * @param bondingCurve The bonding curve for the pool to price NFTs, must be whitelisted
     * @param assetRecipient The address that will receive the assets traders give during trades.
     *                         If set to address(0), assets will be sent to the pool address.
     *                         Not available to TRADE pools.
     * @param receiver Receiver of the LP token generated to represent ownership of the pool
     * @param poolType TOKEN, NFT, or TRADE
     * @param delta The delta value used by the bonding curve. The meaning of delta depends
     * on the specific curve.
     * @param fee The fee taken by the LP in each trade. Can only be non-zero if _poolType is Trade.
     * @param spotPrice The initial selling spot price, in ETH
     * @param royaltyNumerator All trades will result in `royaltyNumerator` * <trade amount> / 1e18
     * being sent to the account to which the traded NFT's royalties are awardable.
     * Must be 0 if `_nft` is not IERC2981 and no recipient override is set.
     * @param royaltyRecipientOverride An address to which all royalties will
     * be paid to if not address(0). This overrides ERC2981 royalties set by
     * the NFT creator, and allows sending royalties to arbitrary addresses
     * even if a collection does not support ERC2981.
     * @param initialNFTIDs The list of IDs of NFTs to transfer from the sender to the pool
     * @param initialTokenBalance The initial token balance sent from the sender to the new pool
     * @return pool The new pool
     */
    struct CreateERC20PoolParams {
        ERC20 token;
        IERC721 nft;
        ICurve bondingCurve;
        address payable assetRecipient;
        address receiver;
        ICollectionPool.PoolType poolType;
        uint128 delta;
        uint96 fee;
        uint128 spotPrice;
        bytes props;
        bytes state;
        uint256 royaltyNumerator;
        address payable royaltyRecipientOverride;
        uint256[] initialNFTIDs;
        uint256 initialTokenBalance;
    }

    function protocolFeeMultiplier() external view returns (uint256);

    function protocolFeeRecipient() external view returns (address payable);

    function carryFeeMultiplier() external view returns (uint256);

    function callAllowed(address target) external view returns (bool);

    function routerStatus(CollectionRouter router) external view returns (bool allowed, bool wasEverAllowed);

    function isPool(address potentialPool, PoolVariant variant) external view returns (bool);

    function requireAuthorizedForToken(address spender, uint256 tokenId) external view;

    function createPoolETH(CreateETHPoolParams calldata params)
        external
        payable
        returns (address pool, uint256 tokenId);

    function createPoolERC20(CreateERC20PoolParams calldata params) external returns (address pool, uint256 tokenId);

    function burn(uint256 tokenId) external;

    /**
     * @return poolParams the parameters of the pool matching `tokenId`.
     */
    function viewPoolParams(uint256 tokenId) external view returns (LPTokenParams721 memory poolParams);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {CurveErrorCodes} from "./CurveErrorCodes.sol";

interface ICurve {
    /**
     * @param spotPrice The current selling spot price of the pool, in tokens
     * @param delta The delta parameter of the pool, what it means depends on the curve
     * @param props The properties of the pool, what it means depends on the curve
     * @param state The state of the pool, what it means depends on the curve
     */
    struct Params {
        uint128 spotPrice;
        uint128 delta;
        bytes props;
        bytes state;
    }

    /**
     * @param trade The amount of fee to send to the pool, in tokens
     * @param protocol The amount of fee to send to the protocol, in tokens
     * @param royalties The amount to pay for each item in the order they
     * are purchased. Always has length `numItems`.
     */
    struct Fees {
        uint256 trade;
        uint256 protocol;
        uint256[] royalties;
    }

    /**
     * @param feeMultiplier Determines how much fee the LP takes from this trade, 18 decimals
     * @param fees.protocolMultiplier Determines how much fee the protocol takes from this trade, 18 decimals
     * @param royaltyNumerator Determines how much of the trade value is awarded as royalties. 5 decimals
     * @param carryFeeMultiplier Determines how much carry fee the protocol takes from this trade, 18 decimals
     */
    struct FeeMultipliers {
        uint256 trade;
        uint256 protocol;
        uint256 royaltyNumerator;
        uint256 carry;
    }

    /**
     * @notice Validates if a delta value is valid for the curve. The criteria for
     * validity can be different for each type of curve, for instance ExponentialCurve
     * requires delta to be greater than 1.
     * @param delta The delta value to be validated
     * @return valid True if delta is valid, false otherwise
     */
    function validateDelta(uint128 delta) external pure returns (bool valid);

    /**
     * @notice Validates if a new spot price is valid for the curve. Spot price is generally assumed to be the immediate sell price of 1 NFT to the pool, in units of the pool's pooled token.
     * @param newSpotPrice The new spot price to be set
     * @return valid True if the new spot price is valid, false otherwise
     */
    function validateSpotPrice(uint128 newSpotPrice) external view returns (bool valid);

    /**
     * @notice Validates if a props value is valid for the curve. The criteria for validity can be different for each type of curve.
     * @param props The props value to be validated
     * @return valid True if props is valid, false otherwise
     */
    function validateProps(bytes calldata props) external view returns (bool valid);

    /**
     * @notice Validates if a state value is valid for the curve. The criteria for validity can be different for each type of curve.
     * @param state The state value to be validated
     * @return valid True if state is valid, false otherwise
     */
    function validateState(bytes calldata state) external view returns (bool valid);

    /**
     * @notice Given the current state of the pool and the trade, computes how much the user
     * should pay to purchase an NFT from the pool, the new spot price, and other values.
     * @dev Do not try to optimize the length of fees.royalties; compiler
     * ^0.8.0 throws a YulException if you try to use an if-guard in the sigmoid
     * calculation loop due to stack depth
     * @param params Parameters of the pool that affect the bonding curve.
     * @param numItems The number of NFTs the user is buying from the pool
     * @param feeMultipliers Determines how much fee is taken from this trade.
     * @return error Any math calculation errors, only Error.OK means the returned values are valid
     * @return newParams The updated parameters of the pool that affect the bonding curve.
     * @return inputValue The amount that the user should pay, in tokens
     * @return fees The amount of fees
     */
    function getBuyInfo(ICurve.Params calldata params, uint256 numItems, ICurve.FeeMultipliers calldata feeMultipliers)
        external
        view
        returns (
            CurveErrorCodes.Error error,
            ICurve.Params calldata newParams,
            uint256 inputValue,
            ICurve.Fees calldata fees
        );

    /**
     * @notice Given the current state of the pool and the trade, computes how much the user
     * should receive when selling NFTs to the pool, the new spot price, and other values.
     * @dev Do not try to optimize the length of fees.royalties; compiler
     * ^0.8.0 throws a YulException if you try to use an if-guard in the sigmoid
     * calculation loop due to stack depth
     * @param params Parameters of the pool that affect the bonding curve.
     * @param numItems The number of NFTs the user is selling to the pool
     * @param feeMultipliers Determines how much fee is taken from this trade.
     * @return error Any math calculation errors, only Error.OK means the returned values are valid
     * @return newParams The updated parameters of the pool that affect the bonding curve.
     * @return outputValue The amount that the user should receive, in tokens
     * @return fees The amount of fees
     */
    function getSellInfo(ICurve.Params calldata params, uint256 numItems, ICurve.FeeMultipliers calldata feeMultipliers)
        external
        view
        returns (
            CurveErrorCodes.Error error,
            ICurve.Params calldata newParams,
            uint256 outputValue,
            ICurve.Fees calldata fees
        );
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface ITokenIDFilter {
    function tokenIDFilterRoot() external view returns (bytes32);
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
// Forked from OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol), 
// to use a custom error

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

    error Reentrancy();

    function __ReentrancyGuard_init() internal {
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
        if (_status == _ENTERED) revert Reentrancy();

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";
import {ICollectionPool} from "../pools/ICollectionPool.sol";
import {CollectionPool} from "../pools/CollectionPool.sol";
import {ICollectionPoolFactory} from "../pools/ICollectionPoolFactory.sol";
import {CurveErrorCodes} from "../bonding-curves/CurveErrorCodes.sol";

contract CollectionRouter {
    using SafeTransferLib for address payable;
    using SafeTransferLib for ERC20;

    struct PoolSwapAny {
        CollectionPool pool;
        uint256 numItems;
    }

    struct PoolSwapSpecific {
        CollectionPool pool;
        uint256[] nftIds;
        bytes32[] proof;
        bool[] proofFlags;
        bytes32[] proofLeaves;
    }

    struct RobustPoolSwapAny {
        PoolSwapAny swapInfo;
        uint256 maxCost;
    }

    struct RobustPoolSwapSpecific {
        PoolSwapSpecific swapInfo;
        uint256 maxCost;
    }

    struct RobustPoolSwapSpecificForToken {
        PoolSwapSpecific swapInfo;
        uint256 minOutput;
    }

    struct NFTsForAnyNFTsTrade {
        PoolSwapSpecific[] nftToTokenTrades;
        PoolSwapAny[] tokenToNFTTrades;
    }

    struct NFTsForSpecificNFTsTrade {
        PoolSwapSpecific[] nftToTokenTrades;
        PoolSwapSpecific[] tokenToNFTTrades;
    }

    struct RobustPoolNFTsFoTokenAndTokenforNFTsTrade {
        RobustPoolSwapSpecific[] tokenToNFTTrades;
        RobustPoolSwapSpecificForToken[] nftToTokenTrades;
        uint256 inputAmount;
        address payable tokenRecipient;
        address nftRecipient;
    }

    modifier checkDeadline(uint256 deadline) {
        _checkDeadline(deadline);
        _;
    }

    ICollectionPoolFactory public immutable factory;

    constructor(ICollectionPoolFactory _factory) {
        factory = _factory;
    }

    /**
     * ETH swaps
     */

    /**
     * @notice Swaps ETH into NFTs using multiple pools.
     * @param swapList The list of pools to trade with and the number of NFTs to buy from each.
     * @param ethRecipient The address that will receive the unspent ETH input
     * @param nftRecipient The address that will receive the NFT output
     * @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
     * @return remainingValue The unspent ETH amount
     */
    function swapETHForAnyNFTs(
        PoolSwapAny[] calldata swapList,
        address payable ethRecipient,
        address nftRecipient,
        uint256 deadline
    ) external payable checkDeadline(deadline) returns (uint256 remainingValue) {
        return _swapETHForAnyNFTs(swapList, msg.value, ethRecipient, nftRecipient);
    }

    /**
     * @notice Swaps ETH into specific NFTs using multiple pools.
     * @param swapList The list of pools to trade with and the IDs of the NFTs to buy from each.
     * @param ethRecipient The address that will receive the unspent ETH input
     * @param nftRecipient The address that will receive the NFT output
     * @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
     * @return remainingValue The unspent ETH amount
     */
    function swapETHForSpecificNFTs(
        PoolSwapSpecific[] calldata swapList,
        address payable ethRecipient,
        address nftRecipient,
        uint256 deadline
    ) external payable checkDeadline(deadline) returns (uint256 remainingValue) {
        return _swapETHForSpecificNFTs(swapList, msg.value, ethRecipient, nftRecipient);
    }

    /**
     * @notice Swaps one set of NFTs into another set of specific NFTs using multiple pools, using
     * ETH as the intermediary.
     * @param trade The struct containing all NFT-to-ETH swaps and ETH-to-NFT swaps.
     * @param minOutput The minimum acceptable total excess ETH received
     * @param ethRecipient The address that will receive the ETH output
     * @param nftRecipient The address that will receive the NFT output
     * @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
     * @return outputAmount The total ETH received
     */
    function swapNFTsForAnyNFTsThroughETH(
        NFTsForAnyNFTsTrade calldata trade,
        uint256 minOutput,
        address payable ethRecipient,
        address nftRecipient,
        uint256 deadline
    ) external payable checkDeadline(deadline) returns (uint256 outputAmount) {
        // Swap NFTs for ETH
        // minOutput of swap set to 0 since we're doing an aggregate slippage check
        outputAmount = _swapNFTsForToken(trade.nftToTokenTrades, 0, payable(address(this)));

        // Add extra value to buy NFTs
        outputAmount += msg.value;

        // Swap ETH for any NFTs
        // cost <= inputValue = outputAmount - minOutput, so outputAmount' = (outputAmount - minOutput - cost) + minOutput >= minOutput
        outputAmount =
            _swapETHForAnyNFTs(trade.tokenToNFTTrades, outputAmount - minOutput, ethRecipient, nftRecipient) + minOutput;
    }

    /**
     * @notice Swaps one set of NFTs into another set of specific NFTs using multiple pools, using
     * ETH as the intermediary.
     * @param trade The struct containing all NFT-to-ETH swaps and ETH-to-NFT swaps.
     * @param minOutput The minimum acceptable total excess ETH received
     * @param ethRecipient The address that will receive the ETH output
     * @param nftRecipient The address that will receive the NFT output
     * @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
     * @return outputAmount The total ETH received
     */
    function swapNFTsForSpecificNFTsThroughETH(
        NFTsForSpecificNFTsTrade calldata trade,
        uint256 minOutput,
        address payable ethRecipient,
        address nftRecipient,
        uint256 deadline
    ) external payable checkDeadline(deadline) returns (uint256 outputAmount) {
        // Swap NFTs for ETH
        // minOutput of swap set to 0 since we're doing an aggregate slippage check
        outputAmount = _swapNFTsForToken(trade.nftToTokenTrades, 0, payable(address(this)));

        // Add extra value to buy NFTs
        outputAmount += msg.value;

        // Swap ETH for specific NFTs
        // cost <= inputValue = outputAmount - minOutput, so outputAmount' = (outputAmount - minOutput - cost) + minOutput >= minOutput
        outputAmount = _swapETHForSpecificNFTs(
            trade.tokenToNFTTrades, outputAmount - minOutput, ethRecipient, nftRecipient
        ) + minOutput;
    }

    /**
     * ERC20 swaps
     *
     * Note: All ERC20 swaps assume that a single ERC20 token is used for all the pools involved.
     * Swapping using multiple tokens in the same transaction is possible, but the slippage checks
     * & the return values will be meaningless, and may lead to undefined behavior.
     *
     * Note: The sender should ideally grant infinite token approval to the router in order for NFT-to-NFT
     * swaps to work smoothly.
     */

    /**
     * @notice Swaps ERC20 tokens into NFTs using multiple pools.
     * @param swapList The list of pools to trade with and the number of NFTs to buy from each.
     * @param inputAmount The amount of ERC20 tokens to add to the ERC20-to-NFT swaps
     * @param nftRecipient The address that will receive the NFT output
     * @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
     * @return remainingValue The unspent token amount
     */
    function swapERC20ForAnyNFTs(
        PoolSwapAny[] calldata swapList,
        uint256 inputAmount,
        address nftRecipient,
        uint256 deadline
    ) external checkDeadline(deadline) returns (uint256 remainingValue) {
        return _swapERC20ForAnyNFTs(swapList, inputAmount, nftRecipient);
    }

    /**
     * @notice Swaps ERC20 tokens into specific NFTs using multiple pools.
     * @param swapList The list of pools to trade with and the IDs of the NFTs to buy from each.
     * @param inputAmount The amount of ERC20 tokens to add to the ERC20-to-NFT swaps
     * @param nftRecipient The address that will receive the NFT output
     * @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
     * @return remainingValue The unspent token amount
     */
    function swapERC20ForSpecificNFTs(
        PoolSwapSpecific[] calldata swapList,
        uint256 inputAmount,
        address nftRecipient,
        uint256 deadline
    ) external checkDeadline(deadline) returns (uint256 remainingValue) {
        return _swapERC20ForSpecificNFTs(swapList, inputAmount, nftRecipient);
    }

    /**
     * @notice Swaps NFTs into ETH/ERC20 using multiple pools.
     * @param swapList The list of pools to trade with and the IDs of the NFTs to sell to each.
     * @param minOutput The minimum acceptable total tokens received
     * @param tokenRecipient The address that will receive the token output
     * @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
     * @return outputAmount The total tokens received
     */
    function swapNFTsForToken(
        PoolSwapSpecific[] calldata swapList,
        uint256 minOutput,
        address tokenRecipient,
        uint256 deadline
    ) external checkDeadline(deadline) returns (uint256 outputAmount) {
        return _swapNFTsForToken(swapList, minOutput, payable(tokenRecipient));
    }

    /**
     * @notice Swaps one set of NFTs into another set of specific NFTs using multiple pools, using
     * an ERC20 token as the intermediary.
     * @param trade The struct containing all NFT-to-ERC20 swaps and ERC20-to-NFT swaps.
     * @param inputAmount The amount of ERC20 tokens to add to the ERC20-to-NFT swaps
     * @param minOutput The minimum acceptable total excess tokens received
     * @param nftRecipient The address that will receive the NFT output
     * @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
     * @return outputAmount The total ERC20 tokens received
     */
    function swapNFTsForAnyNFTsThroughERC20(
        NFTsForAnyNFTsTrade calldata trade,
        uint256 inputAmount,
        uint256 minOutput,
        address nftRecipient,
        uint256 deadline
    ) external checkDeadline(deadline) returns (uint256 outputAmount) {
        // Swap NFTs for ERC20
        // minOutput of swap set to 0 since we're doing an aggregate slippage check
        // output tokens are sent to msg.sender
        outputAmount = _swapNFTsForToken(trade.nftToTokenTrades, 0, payable(msg.sender));

        // Add extra value to buy NFTs
        outputAmount += inputAmount;

        // Swap ERC20 for any NFTs
        // cost <= maxCost = outputAmount - minOutput, so outputAmount' = outputAmount - cost >= minOutput
        // input tokens are taken directly from msg.sender
        outputAmount = _swapERC20ForAnyNFTs(trade.tokenToNFTTrades, outputAmount - minOutput, nftRecipient) + minOutput;
    }

    /**
     * @notice Swaps one set of NFTs into another set of specific NFTs using multiple pools, using
     * an ERC20 token as the intermediary.
     * @param trade The struct containing all NFT-to-ERC20 swaps and ERC20-to-NFT swaps.
     * @param inputAmount The amount of ERC20 tokens to add to the ERC20-to-NFT swaps
     * @param minOutput The minimum acceptable total excess tokens received
     * @param nftRecipient The address that will receive the NFT output
     * @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
     * @return outputAmount The total ERC20 tokens received
     */
    function swapNFTsForSpecificNFTsThroughERC20(
        NFTsForSpecificNFTsTrade calldata trade,
        uint256 inputAmount,
        uint256 minOutput,
        address nftRecipient,
        uint256 deadline
    ) external checkDeadline(deadline) returns (uint256 outputAmount) {
        // Swap NFTs for ERC20
        // minOutput of swap set to 0 since we're doing an aggregate slippage check
        // output tokens are sent to msg.sender
        outputAmount = _swapNFTsForToken(trade.nftToTokenTrades, 0, payable(msg.sender));

        // Add extra value to buy NFTs
        outputAmount += inputAmount;

        // Swap ERC20 for specific NFTs
        // cost <= maxCost = outputAmount - minOutput, so outputAmount' = outputAmount - cost >= minOutput
        // input tokens are taken directly from msg.sender
        outputAmount =
            _swapERC20ForSpecificNFTs(trade.tokenToNFTTrades, outputAmount - minOutput, nftRecipient) + minOutput;
    }

    /**
     * Robust Swaps
     * These are "robust" versions of the NFT<>Token swap functions which will never revert due to slippage
     * Instead, users specify a per-swap max cost. If the price changes more than the user specifies, no swap is attempted. This allows users to specify a batch of swaps, and execute as many of them as possible.
     */

    /**
     * @dev We assume msg.value >= sum of values in maxCostPerPool
     * @notice Swaps as much ETH for any NFTs as possible, respecting the per-swap max cost.
     * @param swapList The list of pools to trade with and the number of NFTs to buy from each.
     * @param ethRecipient The address that will receive the unspent ETH input
     * @param nftRecipient The address that will receive the NFT output
     * @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
     * @return remainingValue The unspent token amount
     */
    function robustSwapETHForAnyNFTs(
        RobustPoolSwapAny[] calldata swapList,
        address payable ethRecipient,
        address nftRecipient,
        uint256 deadline
    ) external payable virtual checkDeadline(deadline) returns (uint256 remainingValue) {
        remainingValue = msg.value;

        // Try doing each swap
        uint256 poolCost;
        CurveErrorCodes.Error error;
        uint256 numSwaps = swapList.length;
        for (uint256 i; i < numSwaps;) {
            // Calculate actual cost per swap
            (error,,,, poolCost,,) = swapList[i].swapInfo.pool.getBuyNFTQuote(swapList[i].swapInfo.numItems);

            // If within our maxCost and no error, proceed
            if (poolCost <= swapList[i].maxCost && error == CurveErrorCodes.Error.OK) {
                // We know how much ETH to send because we already did the math above
                // So we just send that much
                remainingValue -= swapList[i].swapInfo.pool.swapTokenForAnyNFTs{value: poolCost}(
                    swapList[i].swapInfo.numItems, poolCost, nftRecipient, true, msg.sender
                );
            }

            unchecked {
                ++i;
            }
        }

        // Return remaining value to sender
        if (remainingValue > 0) {
            ethRecipient.safeTransferETH(remainingValue);
        }
    }

    /**
     * @dev We assume msg.value >= sum of values in maxCostPerPool
     * @param swapList The list of pools to trade with and the IDs of the NFTs to buy from each.
     * @param ethRecipient The address that will receive the unspent ETH input
     * @param nftRecipient The address that will receive the NFT output
     * @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
     * @return remainingValue The unspent token amount
     */
    function robustSwapETHForSpecificNFTs(
        RobustPoolSwapSpecific[] calldata swapList,
        address payable ethRecipient,
        address nftRecipient,
        uint256 deadline
    ) public payable virtual checkDeadline(deadline) returns (uint256 remainingValue) {
        remainingValue = msg.value;
        uint256 poolCost;
        CurveErrorCodes.Error error;

        // Try doing each swap
        uint256 numSwaps = swapList.length;
        for (uint256 i; i < numSwaps;) {
            // Calculate actual cost per swap
            (error,,,, poolCost,,) = swapList[i].swapInfo.pool.getBuyNFTQuote(swapList[i].swapInfo.nftIds.length);

            // If within our maxCost and no error, proceed
            if (poolCost <= swapList[i].maxCost && error == CurveErrorCodes.Error.OK) {
                // We know how much ETH to send because we already did the math above
                // So we just send that much
                remainingValue -= swapList[i].swapInfo.pool.swapTokenForSpecificNFTs{value: poolCost}(
                    swapList[i].swapInfo.nftIds, poolCost, nftRecipient, true, msg.sender
                );
            }

            unchecked {
                ++i;
            }
        }

        // Return remaining value to sender
        if (remainingValue > 0) {
            ethRecipient.safeTransferETH(remainingValue);
        }
    }

    /**
     * @notice Swaps as many ERC20 tokens for any NFTs as possible, respecting the per-swap max cost.
     * @param swapList The list of pools to trade with and the number of NFTs to buy from each.
     * @param inputAmount The amount of ERC20 tokens to add to the ERC20-to-NFT swaps
     * @param nftRecipient The address that will receive the NFT output
     * @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
     * @return remainingValue The unspent token amount
     */
    function robustSwapERC20ForAnyNFTs(
        RobustPoolSwapAny[] calldata swapList,
        uint256 inputAmount,
        address nftRecipient,
        uint256 deadline
    ) external virtual checkDeadline(deadline) returns (uint256 remainingValue) {
        remainingValue = inputAmount;
        uint256 poolCost;
        CurveErrorCodes.Error error;

        // Try doing each swap
        uint256 numSwaps = swapList.length;
        for (uint256 i; i < numSwaps;) {
            // Calculate actual cost per swap
            (error,,,, poolCost,,) = swapList[i].swapInfo.pool.getBuyNFTQuote(swapList[i].swapInfo.numItems);

            // If within our maxCost and no error, proceed
            if (poolCost <= swapList[i].maxCost && error == CurveErrorCodes.Error.OK) {
                remainingValue -= swapList[i].swapInfo.pool.swapTokenForAnyNFTs(
                    swapList[i].swapInfo.numItems, poolCost, nftRecipient, true, msg.sender
                );
            }

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Swaps as many ERC20 tokens for specific NFTs as possible, respecting the per-swap max cost.
     * @param swapList The list of pools to trade with and the IDs of the NFTs to buy from each.
     * @param inputAmount The amount of ERC20 tokens to add to the ERC20-to-NFT swaps
     *
     * @param nftRecipient The address that will receive the NFT output
     * @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
     * @return remainingValue The unspent token amount
     */
    function robustSwapERC20ForSpecificNFTs(
        RobustPoolSwapSpecific[] calldata swapList,
        uint256 inputAmount,
        address nftRecipient,
        uint256 deadline
    ) public virtual checkDeadline(deadline) returns (uint256 remainingValue) {
        remainingValue = inputAmount;
        uint256 poolCost;
        CurveErrorCodes.Error error;

        // Try doing each swap
        uint256 numSwaps = swapList.length;
        for (uint256 i; i < numSwaps;) {
            // Calculate actual cost per swap
            (error,,,, poolCost,,) = swapList[i].swapInfo.pool.getBuyNFTQuote(swapList[i].swapInfo.nftIds.length);

            // If within our maxCost and no error, proceed
            if (poolCost <= swapList[i].maxCost && error == CurveErrorCodes.Error.OK) {
                remainingValue -= swapList[i].swapInfo.pool.swapTokenForSpecificNFTs(
                    swapList[i].swapInfo.nftIds, poolCost, nftRecipient, true, msg.sender
                );
            }

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Swaps as many NFTs for tokens as possible, respecting the per-swap min output
     * @param swapList The list of pools to trade with and the IDs of the NFTs to sell to each.
     * @param tokenRecipient The address that will receive the token output
     * @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
     * @return outputAmount The total ETH/ERC20 received
     */
    function robustSwapNFTsForToken(
        RobustPoolSwapSpecificForToken[] calldata swapList,
        address payable tokenRecipient,
        uint256 deadline
    ) public virtual checkDeadline(deadline) returns (uint256 outputAmount) {
        // Try doing each swap
        uint256 numSwaps = swapList.length;
        for (uint256 i; i < numSwaps;) {
            uint256 poolOutput;

            // Locally scoped to avoid stack too deep error
            {
                CurveErrorCodes.Error error;
                (error,,,, poolOutput,,) = swapList[i].swapInfo.pool.getSellNFTQuote(swapList[i].swapInfo.nftIds.length);
                if (error != CurveErrorCodes.Error.OK) {
                    unchecked {
                        ++i;
                    }
                    continue;
                }
            }

            // If at least equal to our minOutput, proceed
            if (poolOutput >= swapList[i].minOutput) {
                // Do the swap and update outputAmount with how many tokens we got
                outputAmount += swapList[i].swapInfo.pool.swapNFTsForToken(
                    ICollectionPool.NFTs(
                        swapList[i].swapInfo.nftIds,
                        swapList[i].swapInfo.proof,
                        swapList[i].swapInfo.proofFlags,
                        swapList[i].swapInfo.proofLeaves
                    ),
                    0,
                    tokenRecipient,
                    true,
                    msg.sender
                );
            }

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Buys NFTs with ETH and sells them for tokens in one transaction
     * @param params All the parameters for the swap (packed in struct to avoid stack too deep), containing:
     * - ethToNFTSwapList The list of NFTs to buy
     * - nftToTokenSwapList The list of NFTs to sell
     * - inputAmount The max amount of tokens to send (if ERC20)
     * - tokenRecipient The address that receives tokens from the NFTs sold
     * - nftRecipient The address that receives NFTs
     * - deadline UNIX timestamp deadline for the swap
     */
    function robustSwapETHForSpecificNFTsAndNFTsToToken(RobustPoolNFTsFoTokenAndTokenforNFTsTrade calldata params)
        external
        payable
        virtual
        returns (uint256 remainingValue, uint256 outputAmount)
    {
        {
            remainingValue = msg.value;
            uint256 poolCost;
            CurveErrorCodes.Error error;

            // Try doing each swap
            uint256 numSwaps = params.tokenToNFTTrades.length;
            for (uint256 i; i < numSwaps;) {
                // Calculate actual cost per swap
                (error,,,, poolCost,,) = params.tokenToNFTTrades[i].swapInfo.pool.getBuyNFTQuote(
                    params.tokenToNFTTrades[i].swapInfo.nftIds.length
                );

                // If within our maxCost and no error, proceed
                if (poolCost <= params.tokenToNFTTrades[i].maxCost && error == CurveErrorCodes.Error.OK) {
                    // We know how much ETH to send because we already did the math above
                    // So we just send that much
                    remainingValue -= params.tokenToNFTTrades[i].swapInfo.pool.swapTokenForSpecificNFTs{value: poolCost}(
                        params.tokenToNFTTrades[i].swapInfo.nftIds, poolCost, params.nftRecipient, true, msg.sender
                    );
                }

                unchecked {
                    ++i;
                }
            }

            // Return remaining value to sender
            if (remainingValue > 0) {
                params.tokenRecipient.safeTransferETH(remainingValue);
            }
        }
        {
            // Try doing each swap
            uint256 numSwaps = params.nftToTokenTrades.length;
            for (uint256 i; i < numSwaps;) {
                uint256 poolOutput;

                // Locally scoped to avoid stack too deep error
                {
                    CurveErrorCodes.Error error;
                    (error,,,, poolOutput,,) = params.nftToTokenTrades[i].swapInfo.pool.getSellNFTQuote(
                        params.nftToTokenTrades[i].swapInfo.nftIds.length
                    );
                    if (error != CurveErrorCodes.Error.OK) {
                        unchecked {
                            ++i;
                        }
                        continue;
                    }
                }

                // If at least equal to our minOutput, proceed
                if (poolOutput >= params.nftToTokenTrades[i].minOutput) {
                    // Do the swap and update outputAmount with how many tokens we got
                    outputAmount += params.nftToTokenTrades[i].swapInfo.pool.swapNFTsForToken(
                        ICollectionPool.NFTs(
                            params.nftToTokenTrades[i].swapInfo.nftIds,
                            params.nftToTokenTrades[i].swapInfo.proof,
                            params.nftToTokenTrades[i].swapInfo.proofFlags,
                            params.nftToTokenTrades[i].swapInfo.proofLeaves
                        ),
                        0,
                        params.tokenRecipient,
                        true,
                        msg.sender
                    );
                }

                unchecked {
                    ++i;
                }
            }
        }
    }

    /**
     * @notice Buys NFTs with ERC20, and sells them for tokens in one transaction
     * @param params All the parameters for the swap (packed in struct to avoid stack too deep), containing:
     * - ethToNFTSwapList The list of NFTs to buy
     * - nftToTokenSwapList The list of NFTs to sell
     * - inputAmount The max amount of tokens to send (if ERC20)
     * - tokenRecipient The address that receives tokens from the NFTs sold
     * - nftRecipient The address that receives NFTs
     * - deadline UNIX timestamp deadline for the swap
     */
    function robustSwapERC20ForSpecificNFTsAndNFTsToToken(RobustPoolNFTsFoTokenAndTokenforNFTsTrade calldata params)
        external
        payable
        virtual
        returns (uint256 remainingValue, uint256 outputAmount)
    {
        {
            remainingValue = params.inputAmount;
            uint256 poolCost;
            CurveErrorCodes.Error error;

            // Try doing each swap
            uint256 numSwaps = params.tokenToNFTTrades.length;
            for (uint256 i; i < numSwaps;) {
                // Calculate actual cost per swap
                (error,,,, poolCost,,) = params.tokenToNFTTrades[i].swapInfo.pool.getBuyNFTQuote(
                    params.tokenToNFTTrades[i].swapInfo.nftIds.length
                );

                // If within our maxCost and no error, proceed
                if (poolCost <= params.tokenToNFTTrades[i].maxCost && error == CurveErrorCodes.Error.OK) {
                    remainingValue -= params.tokenToNFTTrades[i].swapInfo.pool.swapTokenForSpecificNFTs(
                        params.tokenToNFTTrades[i].swapInfo.nftIds, poolCost, params.nftRecipient, true, msg.sender
                    );
                }

                unchecked {
                    ++i;
                }
            }
        }
        {
            // Try doing each swap
            uint256 numSwaps = params.nftToTokenTrades.length;
            for (uint256 i; i < numSwaps;) {
                uint256 poolOutput;

                // Locally scoped to avoid stack too deep error
                {
                    CurveErrorCodes.Error error;
                    (error,,,, poolOutput,,) = params.nftToTokenTrades[i].swapInfo.pool.getSellNFTQuote(
                        params.nftToTokenTrades[i].swapInfo.nftIds.length
                    );
                    if (error != CurveErrorCodes.Error.OK) {
                        unchecked {
                            ++i;
                        }
                        continue;
                    }
                }

                // If at least equal to our minOutput, proceed
                if (poolOutput >= params.nftToTokenTrades[i].minOutput) {
                    // Do the swap and update outputAmount with how many tokens we got
                    outputAmount += params.nftToTokenTrades[i].swapInfo.pool.swapNFTsForToken(
                        ICollectionPool.NFTs(
                            params.nftToTokenTrades[i].swapInfo.nftIds,
                            params.nftToTokenTrades[i].swapInfo.proof,
                            params.nftToTokenTrades[i].swapInfo.proofFlags,
                            params.nftToTokenTrades[i].swapInfo.proofLeaves
                        ),
                        0,
                        params.tokenRecipient,
                        true,
                        msg.sender
                    );
                }

                unchecked {
                    ++i;
                }
            }
        }
    }

    receive() external payable {}

    /**
     * Restricted functions
     */

    /**
     * @dev Allows an ERC20 pool contract to transfer ERC20 tokens directly from
     * the sender, in order to minimize the number of token transfers. Only callable by an ERC20 pool.
     * @param token The ERC20 token to transfer
     * @param from The address to transfer tokens from
     * @param to The address to transfer tokens to
     * @param amount The amount of tokens to transfer
     * @param variant The pool variant of the pool contract
     */
    function poolTransferERC20From(
        ERC20 token,
        address from,
        address to,
        uint256 amount,
        ICollectionPoolFactory.PoolVariant variant
    ) external {
        // verify caller is a trusted pool contract
        require(factory.isPool(msg.sender, variant), "Not pool");

        // verify caller is an ERC20 pool
        require(
            variant == ICollectionPoolFactory.PoolVariant.ENUMERABLE_ERC20
                || variant == ICollectionPoolFactory.PoolVariant.MISSING_ENUMERABLE_ERC20,
            "Not ERC20 pool"
        );

        // transfer tokens to pool
        token.safeTransferFrom(from, to, amount);
    }

    /**
     * @dev Allows a pool contract to transfer ERC721 NFTs directly from
     * the sender, in order to minimize the number of token transfers. Only callable by a pool.
     * @param nft The ERC721 NFT to transfer
     * @param from The address to transfer tokens from
     * @param to The address to transfer tokens to
     * @param id The ID of the NFT to transfer
     * @param variant The pool variant of the pool contract
     */
    function poolTransferNFTFrom(
        IERC721 nft,
        address from,
        address to,
        uint256 id,
        ICollectionPoolFactory.PoolVariant variant
    ) external {
        // verify caller is a trusted pool contract
        require(factory.isPool(msg.sender, variant), "Not pool");

        // transfer NFTs to pool
        nft.safeTransferFrom(from, to, id);
    }

    /**
     * Internal functions
     */

    /**
     * @param deadline The last valid time for a swap
     */
    function _checkDeadline(uint256 deadline) internal view {
        require(block.timestamp <= deadline, "Deadline passed");
    }

    /**
     * @notice Internal function used to swap ETH for any NFTs
     * @param swapList The list of pools and swap calldata
     * @param inputAmount The total amount of ETH to send
     * @param ethRecipient The address receiving excess ETH
     * @param nftRecipient The address receiving the NFTs from the pools
     * @return remainingValue The unspent token amount
     */
    function _swapETHForAnyNFTs(
        PoolSwapAny[] calldata swapList,
        uint256 inputAmount,
        address payable ethRecipient,
        address nftRecipient
    ) internal virtual returns (uint256 remainingValue) {
        remainingValue = inputAmount;

        uint256 poolCost;
        CurveErrorCodes.Error error;

        // Do swaps
        uint256 numSwaps = swapList.length;
        for (uint256 i; i < numSwaps;) {
            // Calculate the cost per swap first to send exact amount of ETH over, saves gas by avoiding the need to send back excess ETH
            (error,,,, poolCost,,) = swapList[i].pool.getBuyNFTQuote(swapList[i].numItems);

            // Require no error
            require(error == CurveErrorCodes.Error.OK, "Bonding curve error");

            // Total ETH taken from sender cannot exceed inputAmount
            // because otherwise the deduction from remainingValue will fail
            remainingValue -= swapList[i].pool.swapTokenForAnyNFTs{value: poolCost}(
                swapList[i].numItems, remainingValue, nftRecipient, true, msg.sender
            );

            unchecked {
                ++i;
            }
        }

        // Return remaining value to sender
        if (remainingValue > 0) {
            ethRecipient.safeTransferETH(remainingValue);
        }
    }

    /**
     * @notice Internal function used to swap ETH for a specific set of NFTs
     * @param swapList The list of pools and swap calldata
     * @param inputAmount The total amount of ETH to send
     * @param ethRecipient The address receiving excess ETH
     * @param nftRecipient The address receiving the NFTs from the pools
     * @return remainingValue The unspent token amount
     */
    function _swapETHForSpecificNFTs(
        PoolSwapSpecific[] calldata swapList,
        uint256 inputAmount,
        address payable ethRecipient,
        address nftRecipient
    ) internal virtual returns (uint256 remainingValue) {
        remainingValue = inputAmount;

        uint256 poolCost;
        CurveErrorCodes.Error error;

        // Do swaps
        uint256 numSwaps = swapList.length;
        for (uint256 i; i < numSwaps;) {
            // Calculate the cost per swap first to send exact amount of ETH over, saves gas by avoiding the need to send back excess ETH
            (error,,,, poolCost,,) = swapList[i].pool.getBuyNFTQuote(swapList[i].nftIds.length);

            // Require no errors
            require(error == CurveErrorCodes.Error.OK, "Bonding curve error");

            // Total ETH taken from sender cannot exceed inputAmount
            // because otherwise the deduction from remainingValue will fail
            remainingValue -= swapList[i].pool.swapTokenForSpecificNFTs{value: poolCost}(
                swapList[i].nftIds, remainingValue, nftRecipient, true, msg.sender
            );

            unchecked {
                ++i;
            }
        }

        // Return remaining value to sender
        if (remainingValue > 0) {
            ethRecipient.safeTransferETH(remainingValue);
        }
    }

    /**
     * @notice Internal function used to swap an ERC20 token for any NFTs
     * @dev Note that we don't need to query the pool's bonding curve first for pricing data because
     * we just calculate and take the required amount from the caller during swap time.
     * However, we can't "pull" ETH, which is why for the ETH->NFT swaps, we need to calculate the pricing info
     * to figure out how much the router should send to the pool.
     * @param swapList The list of pools and swap calldata
     * @param inputAmount The total amount of ERC20 tokens to send
     * @param nftRecipient The address receiving the NFTs from the pools
     * @return remainingValue The unspent token amount
     */
    function _swapERC20ForAnyNFTs(PoolSwapAny[] calldata swapList, uint256 inputAmount, address nftRecipient)
        internal
        virtual
        returns (uint256 remainingValue)
    {
        remainingValue = inputAmount;

        // Do swaps
        uint256 numSwaps = swapList.length;
        for (uint256 i; i < numSwaps;) {
            // Tokens are transferred in by the pool calling router.poolTransferERC20From
            // Total tokens taken from sender cannot exceed inputAmount
            // because otherwise the deduction from remainingValue will fail
            remainingValue -= swapList[i].pool.swapTokenForAnyNFTs(
                swapList[i].numItems, remainingValue, nftRecipient, true, msg.sender
            );

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Internal function used to swap an ERC20 token for specific NFTs
     * @dev Note that we don't need to query the pool's bonding curve first for pricing data because
     * we just calculate and take the required amount from the caller during swap time.
     * However, we can't "pull" ETH, which is why for the ETH->NFT swaps, we need to calculate the pricing info
     * to figure out how much the router should send to the pool.
     * @param swapList The list of pools and swap calldata
     * @param inputAmount The total amount of ERC20 tokens to send
     * @param nftRecipient The address receiving the NFTs from the pools
     * @return remainingValue The unspent token amount
     */
    function _swapERC20ForSpecificNFTs(PoolSwapSpecific[] calldata swapList, uint256 inputAmount, address nftRecipient)
        internal
        virtual
        returns (uint256 remainingValue)
    {
        remainingValue = inputAmount;

        // Do swaps
        uint256 numSwaps = swapList.length;
        for (uint256 i; i < numSwaps;) {
            // Tokens are transferred in by the pool calling router.poolTransferERC20From
            // Total tokens taken from sender cannot exceed inputAmount
            // because otherwise the deduction from remainingValue will fail
            remainingValue -= swapList[i].pool.swapTokenForSpecificNFTs(
                swapList[i].nftIds, remainingValue, nftRecipient, true, msg.sender
            );

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Swaps NFTs for tokens, designed to be used for 1 token at a time
     * @dev Calling with multiple tokens is permitted, BUT minOutput will be
     * far from enough of a safety check because different tokens almost certainly have different unit prices.
     * @param swapList The list of pools and swap calldata
     * @param minOutput The minimum number of tokens to be receieved from the swaps
     * @param tokenRecipient The address that receives the tokens
     * @return outputAmount The number of tokens to be received
     */
    function _swapNFTsForToken(PoolSwapSpecific[] calldata swapList, uint256 minOutput, address payable tokenRecipient)
        internal
        virtual
        returns (uint256 outputAmount)
    {
        // Do swaps
        uint256 numSwaps = swapList.length;
        for (uint256 i; i < numSwaps;) {
            // Do the swap for token and then update outputAmount
            // Note: minExpectedTokenOutput is set to 0 since we're doing an aggregate slippage check below
            outputAmount += swapList[i].pool.swapNFTsForToken(
                ICollectionPool.NFTs(
                    swapList[i].nftIds, swapList[i].proof, swapList[i].proofFlags, swapList[i].proofLeaves
                ),
                0,
                tokenRecipient,
                true,
                msg.sender
            );

            unchecked {
                ++i;
            }
        }

        // Aggregate slippage check
        require(outputAmount >= minOutput, "outputAmount too low");
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {ITokenIDFilter} from "./ITokenIDFilter.sol";

contract TokenIDFilter is ITokenIDFilter {
    event AcceptsTokenIDs(address indexed _collection, bytes32 indexed _root, bytes _data);

    // Merkle root
    bytes32 public tokenIDFilterRoot;

    uint32[999] _padding;

    function _setRootAndEmitAcceptedIDs(address collection, bytes32 root, bytes calldata data) internal {
        tokenIDFilterRoot = root;
        emit AcceptsTokenIDs(collection, tokenIDFilterRoot, data);
    }

    function _acceptsTokenID(uint256 tokenID, bytes32[] calldata proof) internal view returns (bool) {
        if (tokenIDFilterRoot == 0) {
            return true;
        }

        // double hash to prevent second preimage attack
        bytes32 leaf = keccak256(abi.encodePacked(keccak256(abi.encodePacked((tokenID)))));

        return MerkleProof.verifyCalldata(proof, tokenIDFilterRoot, leaf);
    }

    function _emitTokenIDs(address collection, bytes calldata data) internal {
        emit AcceptsTokenIDs(collection, tokenIDFilterRoot, data);
    }

    function _acceptsTokenIDs(bytes32[] calldata proof, bool[] calldata proofFlags, bytes32[] calldata leaves)
        internal
        view
        returns (bool)
    {
        if (tokenIDFilterRoot == 0) {
            return true;
        }

        uint256 length = leaves.length;
        bytes32[] memory hashedLeaves = new bytes32[](length);

        for (uint256 i; i < length;) {
            // double hash to prevent second preimage attack
            hashedLeaves[i] = keccak256(abi.encodePacked(keccak256(abi.encodePacked((leaves[i])))));
            unchecked {
                ++i;
            }
        }

        return MerkleProof.multiProofVerify(proof, proofFlags, tokenIDFilterRoot, hashedLeaves);
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be proved to be a part of a Merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and the sibling nodes in `proof`,
     * consuming from one or the other at each step according to the instructions given by
     * `proofFlags`.
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally checks to see if a
     * token-specific URI was set for the token, and if so, it deletes the token URI from
     * the storage mapping.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {ERC165Checker} from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

// @dev Solmate's ERC20 is used instead of OZ's ERC20 so we can use safeTransferLib for cheaper safeTransfers for
// ETH and ERC20 tokens
import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";
import {ReentrancyGuard} from "../lib/ReentrancyGuard.sol";

import {CollectionPool} from ".//CollectionPool.sol";
import {CollectionRouter} from "../routers/CollectionRouter.sol";
import {CollectionPoolETH} from "./CollectionPoolETH.sol";
import {ICurve} from "../bonding-curves/ICurve.sol";
import {CollectionPoolERC20} from ".//CollectionPoolERC20.sol";
import {CollectionPoolCloner} from "../lib/CollectionPoolCloner.sol";
import {ICollectionPoolFactory} from "./ICollectionPoolFactory.sol";
import {CollectionPoolEnumerableETH} from "./CollectionPoolEnumerableETH.sol";
import {CollectionPoolEnumerableERC20} from "./CollectionPoolEnumerableERC20.sol";
import {CollectionPoolMissingEnumerableETH} from "./CollectionPoolMissingEnumerableETH.sol";
import {CollectionPoolMissingEnumerableERC20} from "./CollectionPoolMissingEnumerableERC20.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

contract CollectionPoolFactory is
    Ownable,
    ReentrancyGuard,
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    ICollectionPoolFactory
{
    using CollectionPoolCloner for address;
    using SafeTransferLib for address payable;
    using SafeTransferLib for ERC20;

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    bytes4 private constant INTERFACE_ID_ERC721_ENUMERABLE = type(IERC721Enumerable).interfaceId;

    /**
     * @dev The MAX_PROTOCOL_FEE constant specifies the maximum fee that can be charged by the AMM pool contract
     * for facilitating token or NFT swaps on the decentralized exchange.
     * This fee is charged as a flat percentage of the final traded price for each swap,
     * and it is used to cover the costs associated with running the AMM pool contract and providing liquidity to the decentralized exchange.
     * This is used for NFT/TOKEN trading pools, that have a limited amount of dry powder
     */
    uint256 internal constant MAX_PROTOCOL_FEE = 0.1e18; // 10%, must <= 1 - MAX_FEE
    /**
     * @dev The MAX_CARRY_FEE constant specifies the maximum fee that can be charged by the AMM pool contract for facilitating token
     * or NFT swaps on the decentralized exchange. This fee is charged as a percentage of the fee set by the trading pool creator,
     * which is itself a percentage of the final traded price. This is used for TRADE pools, that form a continuous liquidity pool
     */
    uint256 internal constant MAX_CARRY_FEE = 0.5e18; // 50%

    /// @dev maps the tokenID to the pool address created
    mapping(uint256 => LPTokenParams721) internal _tokenIdToPoolParams;
    /// @dev The ID of the next token that will be minted. Skips 0
    uint256 internal _nextTokenId;

    event NewTokenId(uint256 tokenId);

    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    CollectionPoolEnumerableETH public immutable enumerableETHTemplate;
    CollectionPoolMissingEnumerableETH public immutable missingEnumerableETHTemplate;
    CollectionPoolEnumerableERC20 public immutable enumerableERC20Template;
    CollectionPoolMissingEnumerableERC20 public immutable missingEnumerableERC20Template;
    address payable public override protocolFeeRecipient;

    // Units are in base 1e18
    uint256 public override protocolFeeMultiplier;

    // Units are in base 1e18
    uint256 public override carryFeeMultiplier;

    mapping(ICurve => bool) public bondingCurveAllowed;
    mapping(address => bool) public override callAllowed;

    struct RouterStatus {
        bool allowed;
        bool wasEverAllowed;
    }

    mapping(CollectionRouter => RouterStatus) public override routerStatus;

    string public baseURI;

    event NewPool(address poolAddress);
    event TokenDeposit(address poolAddress);
    event NFTDeposit(address poolAddress);
    event ProtocolFeeRecipientUpdate(address recipientAddress);
    event ProtocolFeeMultiplierUpdate(uint256 newMultiplier);
    event CarryFeeMultiplierUpdate(uint256 newMultiplier);
    event BondingCurveStatusUpdate(ICurve bondingCurve, bool isAllowed);
    event CallTargetStatusUpdate(address target, bool isAllowed);
    event RouterStatusUpdate(CollectionRouter router, bool isAllowed);

    constructor(
        CollectionPoolEnumerableETH _enumerableETHTemplate,
        CollectionPoolMissingEnumerableETH _missingEnumerableETHTemplate,
        CollectionPoolEnumerableERC20 _enumerableERC20Template,
        CollectionPoolMissingEnumerableERC20 _missingEnumerableERC20Template,
        address payable _protocolFeeRecipient,
        uint256 _protocolFeeMultiplier,
        uint256 _carryFeeMultiplier
    ) ERC721("Collectionswap", "CollectionLP") {
        enumerableETHTemplate = _enumerableETHTemplate;
        missingEnumerableETHTemplate = _missingEnumerableETHTemplate;
        enumerableERC20Template = _enumerableERC20Template;
        missingEnumerableERC20Template = _missingEnumerableERC20Template;
        protocolFeeRecipient = _protocolFeeRecipient;

        require(_protocolFeeMultiplier <= MAX_PROTOCOL_FEE, "Protocol fee too large");
        protocolFeeMultiplier = _protocolFeeMultiplier;

        require(_carryFeeMultiplier <= MAX_CARRY_FEE, "Carry fee too large");
        carryFeeMultiplier = _carryFeeMultiplier;
    }

    /**
     * External functions
     */

    function setBaseURI(string calldata _uri) external onlyOwner {
        baseURI = _uri;
    }

    function setTokenURI(string calldata _uri, uint256 tokenId) external onlyOwner {
        _setTokenURI(tokenId, _uri);
    }

    function createPoolETH(CreateETHPoolParams calldata params)
        external
        payable
        returns (address pool, uint256 tokenId)
    {
        require(bondingCurveAllowed[params.bondingCurve], "Bonding curve not whitelisted");

        require(
            params.royaltyNumerator == 0 || IERC165(params.nft).supportsInterface(_INTERFACE_ID_ERC2981)
                || params.royaltyRecipientOverride != address(0),
            "Nonzero royalty for non ERC2981 without override"
        );

        // Check to see if the NFT supports Enumerable to determine which template to use
        address template;
        try IERC165(address(params.nft)).supportsInterface(INTERFACE_ID_ERC721_ENUMERABLE) returns (bool isEnumerable) {
            template = isEnumerable ? address(enumerableETHTemplate) : address(missingEnumerableETHTemplate);
        } catch {
            template = address(missingEnumerableETHTemplate);
        }

        pool = template.cloneETHPool(this, params.bondingCurve, params.nft, uint8(params.poolType));

        // issue new token
        tokenId = mint(params.receiver);

        // save params in mapping
        _tokenIdToPoolParams[tokenId] = LPTokenParams721({
            nftAddress: address(params.nft),
            bondingCurveAddress: address(params.bondingCurve),
            tokenAddress: ETH_ADDRESS,
            poolAddress: payable(pool),
            fee: params.fee,
            delta: params.delta,
            royaltyNumerator: params.royaltyNumerator
        });

        _initializePoolETH(CollectionPoolETH(payable(pool)), params, tokenId);

        emit NewPool(pool);
    }

    /**
     * @notice Creates a filtered pool contract using EIP-1167.
     * @param params The parameters to create ETH pool
     * @param filterParams The parameters needed for the filtering functionality
     * @return pool The new pool
     */
    function createPoolETHFiltered(CreateETHPoolParams calldata params, NFTFilterParams calldata filterParams)
        external
        payable
        returns (address pool, uint256 tokenId)
    {
        require(bondingCurveAllowed[params.bondingCurve], "Bonding curve not whitelisted");

        require(
            params.royaltyNumerator == 0 || IERC165(params.nft).supportsInterface(_INTERFACE_ID_ERC2981)
                || params.royaltyRecipientOverride != address(0),
            "Nonzero royalty for non ERC2981 without override"
        );

        // Check to see if the NFT supports Enumerable to determine which template to use
        address template;
        try IERC165(address(params.nft)).supportsInterface(INTERFACE_ID_ERC721_ENUMERABLE) returns (bool isEnumerable) {
            template = isEnumerable ? address(enumerableETHTemplate) : address(missingEnumerableETHTemplate);
        } catch {
            template = address(missingEnumerableETHTemplate);
        }

        pool = template.cloneETHPool(this, params.bondingCurve, params.nft, uint8(params.poolType));

        // issue new token
        tokenId = mint(params.receiver);

        // save params in mapping
        _tokenIdToPoolParams[tokenId] = LPTokenParams721({
            nftAddress: address(params.nft),
            bondingCurveAddress: address(params.bondingCurve),
            tokenAddress: ETH_ADDRESS,
            poolAddress: payable(pool),
            fee: params.fee,
            delta: params.delta,
            royaltyNumerator: params.royaltyNumerator
        });

        _initializePoolETHFiltered(CollectionPoolETH(payable(pool)), params, filterParams, tokenId);
        emit NewPool(pool);
    }

    function createPoolERC20(CreateERC20PoolParams calldata params) external returns (address pool, uint256 tokenId) {
        require(bondingCurveAllowed[params.bondingCurve], "Bonding curve not whitelisted");

        require(
            params.royaltyNumerator == 0 || IERC165(params.nft).supportsInterface(_INTERFACE_ID_ERC2981)
                || params.royaltyRecipientOverride != address(0),
            "Nonzero royalty for non ERC2981 without override"
        );

        // Check to see if the NFT supports Enumerable to determine which template to use
        address template;
        try IERC165(address(params.nft)).supportsInterface(INTERFACE_ID_ERC721_ENUMERABLE) returns (bool isEnumerable) {
            template = isEnumerable ? address(enumerableERC20Template) : address(missingEnumerableERC20Template);
        } catch {
            template = address(missingEnumerableERC20Template);
        }

        pool = template.cloneERC20Pool(this, params.bondingCurve, params.nft, uint8(params.poolType), params.token);

        // issue new token
        tokenId = mint(params.receiver);

        // save params in mapping
        _tokenIdToPoolParams[tokenId] = LPTokenParams721({
            nftAddress: address(params.nft),
            bondingCurveAddress: address(params.bondingCurve),
            tokenAddress: address(params.token),
            poolAddress: payable(pool),
            fee: params.fee,
            delta: params.delta,
            royaltyNumerator: params.royaltyNumerator
        });

        _initializePoolERC20(CollectionPoolERC20(payable(pool)), params, tokenId);

        emit NewPool(pool);
    }

    function createPoolERC20Filtered(CreateERC20PoolParams calldata params, NFTFilterParams calldata filterParams)
        external
        returns (address pool, uint256 tokenId)
    {
        require(bondingCurveAllowed[params.bondingCurve], "Bonding curve not whitelisted");

        require(
            params.royaltyNumerator == 0 || IERC165(params.nft).supportsInterface(_INTERFACE_ID_ERC2981)
                || params.royaltyRecipientOverride != address(0),
            "Nonzero royalty for non ERC2981 without override"
        );

        // Check to see if the NFT supports Enumerable to determine which template to use
        address template;
        try IERC165(address(params.nft)).supportsInterface(INTERFACE_ID_ERC721_ENUMERABLE) returns (bool isEnumerable) {
            template = isEnumerable ? address(enumerableERC20Template) : address(missingEnumerableERC20Template);
        } catch {
            template = address(missingEnumerableERC20Template);
        }

        pool = template.cloneERC20Pool(this, params.bondingCurve, params.nft, uint8(params.poolType), params.token);

        // issue new token
        tokenId = mint(params.receiver);

        // save params in mapping
        _tokenIdToPoolParams[tokenId] = LPTokenParams721({
            nftAddress: address(params.nft),
            bondingCurveAddress: address(params.bondingCurve),
            tokenAddress: address(params.token),
            poolAddress: payable(pool),
            fee: params.fee,
            delta: params.delta,
            royaltyNumerator: params.royaltyNumerator
        });

        _initializePoolERC20Filtered(CollectionPoolERC20(payable(pool)), params, filterParams, tokenId);

        emit NewPool(address(pool));
    }

    /**
     * @return poolParams the parameters of the pool matching `tokenId`.
     */
    function viewPoolParams(uint256 tokenId) public view returns (LPTokenParams721 memory poolParams) {
        poolParams = _tokenIdToPoolParams[tokenId];
    }

    /**
     * @notice Checks if an address is a CollectionPool. Uses the fact that the pools are EIP-1167 minimal proxies.
     * @param potentialPool The address to check
     * @param variant The pool variant (NFT is enumerable or not, pool uses ETH or ERC20)
     * @dev The PoolCloner contract is a utility contract that is used by the PoolFactory contract to create new instances of automated market maker (AMM) pools.
     * @return True if the address is the specified pool variant, false otherwise
     */
    function isPool(address potentialPool, PoolVariant variant) public view override returns (bool) {
        if (variant == PoolVariant.ENUMERABLE_ERC20) {
            return CollectionPoolCloner.isERC20PoolClone(address(this), address(enumerableERC20Template), potentialPool);
        } else if (variant == PoolVariant.MISSING_ENUMERABLE_ERC20) {
            return CollectionPoolCloner.isERC20PoolClone(
                address(this), address(missingEnumerableERC20Template), potentialPool
            );
        } else if (variant == PoolVariant.ENUMERABLE_ETH) {
            return CollectionPoolCloner.isETHPoolClone(address(this), address(enumerableETHTemplate), potentialPool);
        } else if (variant == PoolVariant.MISSING_ENUMERABLE_ETH) {
            return
                CollectionPoolCloner.isETHPoolClone(address(this), address(missingEnumerableETHTemplate), potentialPool);
        } else {
            // invalid input
            return false;
        }
    }

    /**
     * @notice Allows receiving ETH in order to receive protocol fees
     */
    receive() external payable {}

    /**
     * Admin functions
     */

    /**
     * @notice Withdraws the ETH balance to the protocol fee recipient.
     * Only callable by the owner.
     */
    function withdrawETHProtocolFees() external onlyOwner {
        protocolFeeRecipient.safeTransferETH(address(this).balance);
    }

    /**
     * @notice Withdraws ERC20 tokens to the protocol fee recipient. Only callable by the owner.
     * @param token The token to transfer
     * @param amount The amount of tokens to transfer
     */
    function withdrawERC20ProtocolFees(ERC20 token, uint256 amount) external onlyOwner {
        token.safeTransfer(protocolFeeRecipient, amount);
    }

    /**
     * @notice Changes the protocol fee recipient address. Only callable by the owner.
     * @param _protocolFeeRecipient The new fee recipient
     */
    function changeProtocolFeeRecipient(address payable _protocolFeeRecipient) external onlyOwner {
        require(_protocolFeeRecipient != address(0), "0 address");
        protocolFeeRecipient = _protocolFeeRecipient;
        emit ProtocolFeeRecipientUpdate(_protocolFeeRecipient);
    }

    /**
     * @notice Changes the protocol fee multiplier. Only callable by the owner.
     * @param _protocolFeeMultiplier The new fee multiplier, 18 decimals
     */
    function changeProtocolFeeMultiplier(uint256 _protocolFeeMultiplier) external onlyOwner {
        require(_protocolFeeMultiplier <= MAX_PROTOCOL_FEE, "Fee too large");
        protocolFeeMultiplier = _protocolFeeMultiplier;
        emit ProtocolFeeMultiplierUpdate(_protocolFeeMultiplier);
    }

    /**
     * @notice Changes the carry fee multiplier. Only callable by the owner.
     * @param _carryFeeMultiplier The new fee multiplier, 18 decimals
     */
    function changeCarryFeeMultiplier(uint256 _carryFeeMultiplier) external onlyOwner {
        require(_carryFeeMultiplier <= MAX_CARRY_FEE, "Fee too large");
        carryFeeMultiplier = _carryFeeMultiplier;
        emit CarryFeeMultiplierUpdate(_carryFeeMultiplier);
    }

    /**
     * @notice Sets the whitelist status of a bonding curve contract. Only callable by the owner.
     * @param bondingCurve The bonding curve contract
     * @param isAllowed True to whitelist, false to remove from whitelist
     */
    function setBondingCurveAllowed(ICurve bondingCurve, bool isAllowed) external onlyOwner {
        bondingCurveAllowed[bondingCurve] = isAllowed;
        emit BondingCurveStatusUpdate(bondingCurve, isAllowed);
    }

    /**
     * @notice Sets the whitelist status of a contract to be called arbitrarily by a pool.
     * Only callable by the owner.
     * @param target The target contract
     * @param isAllowed True to whitelist, false to remove from whitelist
     */
    function setCallAllowed(address payable target, bool isAllowed) external onlyOwner {
        // ensure target is not / was not ever a router
        if (isAllowed) {
            require(!routerStatus[CollectionRouter(target)].wasEverAllowed, "Can't call router");
        }

        callAllowed[target] = isAllowed;
        emit CallTargetStatusUpdate(target, isAllowed);
    }

    /**
     * @notice Updates the router whitelist. Only callable by the owner.
     * @param _router The router
     * @param isAllowed True to whitelist, false to remove from whitelist
     */
    function setRouterAllowed(CollectionRouter _router, bool isAllowed) external onlyOwner {
        // ensure target is not arbitrarily callable by pools
        if (isAllowed) {
            require(!callAllowed[address(_router)], "Can't call router");
        }
        routerStatus[_router] = RouterStatus({allowed: isAllowed, wasEverAllowed: true});

        emit RouterStatusUpdate(_router, isAllowed);
    }

    /**
     * Internal functions
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _initializePoolETH(CollectionPoolETH _pool, CreateETHPoolParams calldata _params, uint256 tokenId)
        internal
    {
        // initialize pool
        _pool.initialize(
            tokenId,
            _params.assetRecipient,
            _params.delta,
            _params.fee,
            _params.spotPrice,
            _params.props,
            _params.state,
            _params.royaltyNumerator,
            _params.royaltyRecipientOverride
        );

        // transfer initial ETH to pool
        payable(address(_pool)).safeTransferETH(msg.value);

        // transfer initial NFTs from sender to pool
        uint256 numNFTs = _params.initialNFTIDs.length;
        for (uint256 i; i < numNFTs;) {
            _params.nft.safeTransferFrom(msg.sender, address(_pool), _params.initialNFTIDs[i]);

            unchecked {
                ++i;
            }
        }
    }

    function _initializePoolETHFiltered(
        CollectionPoolETH _pool,
        CreateETHPoolParams calldata _params,
        NFTFilterParams calldata _filterParams,
        uint256 tokenId
    ) internal {
        // initialize pool
        _pool.initialize(
            tokenId,
            _params.assetRecipient,
            _params.delta,
            _params.fee,
            _params.spotPrice,
            _params.props,
            _params.state,
            _params.royaltyNumerator,
            _params.royaltyRecipientOverride
        );
        _pool.setTokenIDFilter(_filterParams.merkleRoot, _filterParams.encodedTokenIDs);

        require(
            _pool.acceptsTokenIDs(
                _filterParams.initialProof, _filterParams.initialProofFlags, _filterParams.initialProofLeaves
            ),
            "NFT not allowed"
        );

        // transfer initial ETH to pool
        payable(address(_pool)).safeTransferETH(msg.value);

        // transfer initial NFTs from sender to pool
        uint256 numNFTs = _params.initialNFTIDs.length;
        for (uint256 i; i < numNFTs;) {
            _params.nft.safeTransferFrom(msg.sender, address(_pool), _params.initialNFTIDs[i]);

            unchecked {
                ++i;
            }
        }
    }

    function _initializePoolERC20(CollectionPoolERC20 _pool, CreateERC20PoolParams calldata _params, uint256 tokenId)
        internal
    {
        // initialize pool
        _pool.initialize(
            tokenId,
            _params.assetRecipient,
            _params.delta,
            _params.fee,
            _params.spotPrice,
            _params.props,
            _params.state,
            _params.royaltyNumerator,
            _params.royaltyRecipientOverride
        );

        // transfer initial tokens to pool
        _params.token.safeTransferFrom(msg.sender, address(_pool), _params.initialTokenBalance);

        // transfer initial NFTs from sender to pool
        uint256 numNFTs = _params.initialNFTIDs.length;
        for (uint256 i; i < numNFTs;) {
            _params.nft.safeTransferFrom(msg.sender, address(_pool), _params.initialNFTIDs[i]);

            unchecked {
                ++i;
            }
        }
    }

    function _initializePoolERC20Filtered(
        CollectionPoolERC20 _pool,
        CreateERC20PoolParams calldata _params,
        NFTFilterParams calldata _filterParams,
        uint256 tokenId
    ) internal {
        // initialize pool
        _pool.initialize(
            tokenId,
            _params.assetRecipient,
            _params.delta,
            _params.fee,
            _params.spotPrice,
            _params.props,
            _params.state,
            _params.royaltyNumerator,
            _params.royaltyRecipientOverride
        );
        _pool.setTokenIDFilter(_filterParams.merkleRoot, _filterParams.encodedTokenIDs);

        require(
            _pool.acceptsTokenIDs(
                _filterParams.initialProof, _filterParams.initialProofFlags, _filterParams.initialProofLeaves
            ),
            "NFT not allowed"
        );

        // transfer initial tokens to pool
        _params.token.safeTransferFrom(msg.sender, address(_pool), _params.initialTokenBalance);

        // transfer initial NFTs from sender to pool
        uint256 numNFTs = _params.initialNFTIDs.length;
        for (uint256 i; i < numNFTs;) {
            _params.nft.safeTransferFrom(msg.sender, address(_pool), _params.initialNFTIDs[i]);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Used to deposit NFTs into a pool after creation and emit an event for indexing (if recipient is indeed a pool)
     */
    function depositNFTs(
        IERC721 _nft,
        uint256[] calldata ids,
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] calldata proofLeaves,
        address recipient
    ) external {
        bool _isPool = isPool(recipient, PoolVariant.ENUMERABLE_ERC20) || isPool(recipient, PoolVariant.ENUMERABLE_ETH)
            || isPool(recipient, PoolVariant.MISSING_ENUMERABLE_ERC20)
            || isPool(recipient, PoolVariant.MISSING_ENUMERABLE_ETH);

        if (_isPool) {
            require(CollectionPool(recipient).acceptsTokenIDs(proof, proofFlags, proofLeaves), "NFT not allowed");
        }

        // transfer NFTs from caller to recipient
        uint256 numNFTs = ids.length;
        for (uint256 i; i < numNFTs;) {
            _nft.safeTransferFrom(msg.sender, recipient, ids[i]);

            unchecked {
                ++i;
            }
        }

        if (_isPool) {
            emit NFTDeposit(recipient);
        }
    }

    /**
     * @dev Used to deposit ERC20s into a pool after creation and emit an event for indexing (if recipient is indeed an ERC20 pool
     * and the token matches)
     */
    function depositERC20(ERC20 token, address recipient, uint256 amount) external {
        token.safeTransferFrom(msg.sender, recipient, amount);
        if (isPool(recipient, PoolVariant.ENUMERABLE_ERC20) || isPool(recipient, PoolVariant.MISSING_ENUMERABLE_ERC20))
        {
            if (token == CollectionPoolERC20(recipient).token()) {
                emit TokenDeposit(recipient);
            }
        }
    }

    function requireAuthorizedForToken(address spender, uint256 tokenId) external view {
        require(_isApprovedOrOwner(spender, tokenId), "Not approved");
    }

    /// @dev requires LP token owner to give allowance to this factory contract for asset withdrawals
    /// @dev withdrawn assets are sent directly to the LPToken owner
    /// @dev does not withdraw airdropped assets, that should be done prior to calling this function
    function burn(uint256 tokenId) external nonReentrant {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not approved");
        LPTokenParams721 memory poolParams = viewPoolParams(tokenId);
        uint256[] memory heldNftIds;

        // withdraw all ETH / ERC20
        if (poolParams.tokenAddress == ETH_ADDRESS) {
            // withdraw ETH, sent to owner of LPToken
            CollectionPoolETH pool = CollectionPoolETH(poolParams.poolAddress);
            pool.withdrawAllETH();

            // then withdraw NFTs
            heldNftIds = pool.getAllHeldIds();
            pool.withdrawERC721(IERC721(poolParams.nftAddress), heldNftIds);
        } else {
            // withdraw ERC20
            CollectionPoolERC20 pool = CollectionPoolERC20(poolParams.poolAddress);
            pool.withdrawAllERC20();
            heldNftIds = pool.getAllHeldIds();

            // then withdraw NFTs
            heldNftIds = pool.getAllHeldIds();
            pool.withdrawERC721(IERC721(poolParams.nftAddress), heldNftIds);
        }

        delete _tokenIdToPoolParams[tokenId];
        _burn(tokenId);
    }

    function mint(address recipient) internal returns (uint256 tokenId) {
        _safeMint(recipient, (tokenId = ++_nextTokenId));

        emit NewTokenId(tokenId);
    }

    // overrides required by Solidiity for ERC721 contract
    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override (ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override (ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override (IERC165, ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) public view override (ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";
import {ICollectionPool} from "./ICollectionPool.sol";
import {CollectionPool} from "./CollectionPool.sol";
import {ICollectionPoolFactory} from "./ICollectionPoolFactory.sol";
import {ICurve} from "../bonding-curves/ICurve.sol";

/**
 * @title An NFT/Token pool where the token is ETH
 * @author Collection
 */
abstract contract CollectionPoolETH is CollectionPool {
    using SafeTransferLib for address payable;
    using SafeTransferLib for ERC20;

    uint256 internal constant IMMUTABLE_PARAMS_LENGTH = 61;

    /// @inheritdoc CollectionPool
    function _pullTokenInputAndPayProtocolFee(
        uint256 inputAmount,
        bool, /*isRouter*/
        address, /*routerCaller*/
        ICollectionPoolFactory _factory,
        uint256 protocolFee,
        RoyaltyDue[] memory royaltiesDue
    ) internal override {
        require(msg.value >= inputAmount, "Sent too little ETH");

        // Pay royalties first to obtain total amount of royalties paid
        uint256 length = royaltiesDue.length;
        uint256 totalRoyaltiesPaid;

        for (uint256 i = 0; i < length;) {
            RoyaltyDue memory due = royaltiesDue[i];
            uint256 royaltyAmount = due.amount;
            totalRoyaltiesPaid += royaltyAmount;
            if (royaltyAmount > 0) {
                address recipient = getRoyaltyRecipient(payable(due.recipient));
                payable(recipient).safeTransferETH(royaltyAmount);
            }

            unchecked {
                ++i;
            }
        }

        // Transfer inputAmount ETH to assetRecipient if it's been set
        address payable _assetRecipient = getAssetRecipient();
        if (_assetRecipient != address(this)) {
            _assetRecipient.safeTransferETH(inputAmount - protocolFee - totalRoyaltiesPaid);
        }

        // Take protocol fee
        if (protocolFee > 0) {
            // Round down to the actual ETH balance if there are numerical stability issues with the bonding curve calculations
            if (protocolFee > address(this).balance) {
                protocolFee = address(this).balance;
            }

            if (protocolFee > 0) {
                payable(address(_factory)).safeTransferETH(protocolFee);
            }
        }
    }

    /// @inheritdoc CollectionPool
    function _refundTokenToSender(uint256 inputAmount) internal override {
        // Give excess ETH back to caller
        if (msg.value > inputAmount) {
            payable(msg.sender).safeTransferETH(msg.value - inputAmount);
        }
    }

    /// @inheritdoc CollectionPool
    function _payProtocolFeeFromPool(ICollectionPoolFactory _factory, uint256 protocolFee) internal override {
        // Take protocol fee
        if (protocolFee > 0) {
            // Round down to the actual ETH balance if there are numerical stability issues with the bonding curve calculations
            if (protocolFee > address(this).balance) {
                protocolFee = address(this).balance;
            }

            if (protocolFee > 0) {
                payable(address(_factory)).safeTransferETH(protocolFee);
            }
        }
    }

    /// @inheritdoc CollectionPool
    function _sendTokenOutput(address payable tokenRecipient, uint256 outputAmount, RoyaltyDue[] memory royaltiesDue)
        internal
        override
    {
        // Unfortunately we need to duplicate work here
        uint256 length = royaltiesDue.length;
        uint256 totalRoyaltiesDue;
        for (uint256 i = 0; i < length;) {
            totalRoyaltiesDue += royaltiesDue[i].amount;
            unchecked {
                ++i;
            }
        }

        // Send ETH to caller
        if (outputAmount > 0) {
            require(address(this).balance >= outputAmount + tradeFee + totalRoyaltiesDue, "Too little ETH");
            tokenRecipient.safeTransferETH(outputAmount);
        }

        for (uint256 i = 0; i < length;) {
            RoyaltyDue memory due = royaltiesDue[i];
            address royaltyRecipient = getRoyaltyRecipient(payable(due.recipient));
            uint256 royaltyAmount = due.amount;
            if (royaltyAmount > 0) {
                payable(royaltyRecipient).safeTransferETH(royaltyAmount);
            }

            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc CollectionPool
    // @dev see CollectionPoolCloner for params length calculation
    function _immutableParamsLength() internal pure override returns (uint256) {
        return IMMUTABLE_PARAMS_LENGTH;
    }

    /**
     * @notice Withdraws all token owned by the pool to the owner address.
     * @dev Only callable by the owner.
     */
    function withdrawAllETH() external onlyAuthorized {
        tradeFee = 0;

        _withdrawETH(address(this).balance);
    }

    /**
     * @notice Withdraws a specified amount of token owned by the pool to the owner address.
     * @dev Only callable by the owner.
     * @param amount The amount of token to send to the owner. If the pool's balance is less than
     * this value, the transaction will be reverted.
     */
    function withdrawETH(uint256 amount) external onlyAuthorized {
        require(address(this).balance >= amount + tradeFee, "Too little ETH");

        _withdrawETH(amount);
    }

    /// @inheritdoc ICollectionPool
    function withdrawERC20(ERC20 a, uint256 amount) external onlyAuthorized {
        a.safeTransfer(owner(), amount);
    }

    /// @inheritdoc CollectionPool
    function withdrawTradeFee() external override onlyOwner {
        uint256 _tradeFee = tradeFee;
        if (_tradeFee > 0) {
            tradeFee = 0;

            _withdrawETH(_tradeFee);
        }
    }

    /**
     * @dev All ETH transfers into the pool are accepted. This is the main method
     * for the owner to top up the pool's token reserves.
     */
    receive() external payable {
        emit TokenDeposit(msg.value);
    }

    /**
     * @dev All ETH transfers into the pool are accepted. This is the main method
     * for the owner to top up the pool's token reserves.
     */
    fallback() external payable {
        // Only allow calls without function selector
        require(msg.data.length == _immutableParamsLength());
        emit TokenDeposit(msg.value);
    }

    function _withdrawETH(uint256 amount) internal {
        payable(owner()).safeTransferETH(amount);

        // emit event since ETH is the pool token
        emit TokenWithdrawal(amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ICollectionPool} from "./ICollectionPool.sol";
import {CollectionPool} from "./CollectionPool.sol";
import {ICollectionPoolFactory} from "./ICollectionPoolFactory.sol";
import {CollectionRouter} from "../routers/CollectionRouter.sol";
import {ICurve} from "../bonding-curves/ICurve.sol";
import {CurveErrorCodes} from "../bonding-curves/CurveErrorCodes.sol";

/**
 * @title An NFT/Token pool where the token is an ERC20
 * @author Collection
 */
abstract contract CollectionPoolERC20 is CollectionPool {
    using SafeTransferLib for ERC20;

    uint256 internal constant IMMUTABLE_PARAMS_LENGTH = 81;

    /**
     * @notice Returns the ERC20 token associated with the pool
     * @dev See CollectionPoolCloner for an explanation on how this works
     */
    function token() public pure returns (ERC20 _token) {
        uint256 paramsLength = _immutableParamsLength();
        assembly {
            _token := shr(0x60, calldataload(add(sub(calldatasize(), paramsLength), 61)))
        }
    }

    /// @inheritdoc CollectionPool
    function _pullTokenInputAndPayProtocolFee(
        uint256 inputAmount,
        bool isRouter,
        address routerCaller,
        ICollectionPoolFactory _factory,
        uint256 protocolFee,
        RoyaltyDue[] memory royaltiesDue
    ) internal override {
        require(msg.value == 0, "ERC20 pool");

        ERC20 _token = token();
        address _assetRecipient = getAssetRecipient();

        if (isRouter) {
            // Verify if router is allowed
            CollectionRouter router = CollectionRouter(payable(msg.sender));

            // Locally scoped to avoid stack too deep
            {
                (bool routerAllowed,) = _factory.routerStatus(router);
                require(routerAllowed, "Not router");
            }

            // Pay royalties first to obtain total amount of royalties paid
            uint256 length = royaltiesDue.length;
            uint256 totalRoyaltiesPaid;

            for (uint256 i = 0; i < length;) {
                // Cache state and then call router to transfer tokens from user
                uint256 royaltyAmount;
                address royaltyRecipient;

                // Locally scoped to avoid stack too deep
                {
                    RoyaltyDue memory due = royaltiesDue[i];
                    royaltyAmount = due.amount;
                    royaltyRecipient = getRoyaltyRecipient(payable(due.recipient));
                }

                uint256 royaltyInitBalance = _token.balanceOf(royaltyRecipient);
                if (royaltyAmount > 0) {
                    totalRoyaltiesPaid += royaltyAmount;

                    router.poolTransferERC20From(_token, routerCaller, royaltyRecipient, royaltyAmount, poolVariant());

                    // Verify token transfer (protect pool against malicious router)
                    require(
                        _token.balanceOf(royaltyRecipient) - royaltyInitBalance == royaltyAmount,
                        "ERC20 royalty not transferred in"
                    );
                }

                unchecked {
                    ++i;
                }
            }

            // Cache state and then call router to transfer tokens from user
            uint256 beforeBalance = _token.balanceOf(_assetRecipient);
            uint256 amountToAssetRecipient = inputAmount - protocolFee - totalRoyaltiesPaid;
            router.poolTransferERC20From(_token, routerCaller, _assetRecipient, amountToAssetRecipient, poolVariant());

            // Verify token transfer (protect pool against malicious router)
            require(
                _token.balanceOf(_assetRecipient) - beforeBalance == amountToAssetRecipient, "ERC20 not transferred in"
            );

            router.poolTransferERC20From(_token, routerCaller, address(_factory), protocolFee, poolVariant());

            // Note: no check for factory balance's because router is assumed to be set by factory owner
            // so there is no incentive to *not* pay protocol fee
        } else {
            // Pay royalties first to obtain total amount of royalties paid
            uint256 length = royaltiesDue.length;
            uint256 totalRoyaltiesPaid;

            for (uint256 i = 0; i < length;) {
                RoyaltyDue memory due = royaltiesDue[i];
                uint256 royaltyAmount = due.amount;
                address royaltyRecipient = getRoyaltyRecipient(payable(due.recipient));
                if (royaltyAmount > 0) {
                    totalRoyaltiesPaid += royaltyAmount;

                    _token.safeTransferFrom(msg.sender, royaltyRecipient, royaltyAmount);
                }

                unchecked {
                    ++i;
                }
            }

            // Transfer tokens directly
            _token.safeTransferFrom(msg.sender, _assetRecipient, inputAmount - protocolFee - totalRoyaltiesPaid);

            // Take protocol fee (if it exists)
            if (protocolFee > 0) {
                _token.safeTransferFrom(msg.sender, address(_factory), protocolFee);
            }
        }
    }

    /// @inheritdoc CollectionPool
    function _refundTokenToSender(uint256 inputAmount) internal override {
        // Do nothing since we transferred the exact input amount
    }

    /// @inheritdoc CollectionPool
    function _payProtocolFeeFromPool(ICollectionPoolFactory _factory, uint256 protocolFee) internal override {
        // Take protocol fee (if it exists)
        if (protocolFee > 0) {
            ERC20 _token = token();

            // Round down to the actual token balance if there are numerical stability issues with the bonding curve calculations
            uint256 poolTokenBalance = _token.balanceOf(address(this));
            if (protocolFee > poolTokenBalance) {
                protocolFee = poolTokenBalance;
            }
            if (protocolFee > 0) {
                _token.safeTransfer(address(_factory), protocolFee);
            }
        }
    }

    /// @inheritdoc CollectionPool
    function _sendTokenOutput(address payable tokenRecipient, uint256 outputAmount, RoyaltyDue[] memory royaltiesDue)
        internal
        override
    {
        // Unfortunately we need to duplicate work here
        uint256 length = royaltiesDue.length;
        uint256 totalRoyaltiesDue;
        for (uint256 i = 0; i < length;) {
            totalRoyaltiesDue += royaltiesDue[i].amount;
            unchecked {
                ++i;
            }
        }

        // Send tokens to caller
        if (outputAmount > 0) {
            ERC20 _token = token();
            require(_token.balanceOf(address(this)) >= outputAmount + tradeFee + totalRoyaltiesDue, "Too little ERC20");
            _token.safeTransfer(tokenRecipient, outputAmount);
        }

        for (uint256 i = 0; i < length;) {
            RoyaltyDue memory due = royaltiesDue[i];
            uint256 royaltyAmount = due.amount;
            if (royaltyAmount > 0) {
                address royaltyRecipient = getRoyaltyRecipient(payable(due.recipient));
                token().safeTransfer(royaltyRecipient, royaltyAmount);
            }

            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc CollectionPool
    // @dev see CollectionPoolCloner for params length calculation
    function _immutableParamsLength() internal pure override returns (uint256) {
        return IMMUTABLE_PARAMS_LENGTH;
    }

    /**
     * @notice Withdraws all pool token owned by the pool to the owner address.
     * @dev Only callable by the owner.
     */
    function withdrawAllERC20() external onlyAuthorized {
        tradeFee = 0;

        ERC20 _token = token();
        uint256 amount = _token.balanceOf(address(this));
        _token.safeTransfer(owner(), amount);

        // emit event since it is the pool token
        emit TokenWithdrawal(amount);
    }

    /// @inheritdoc ICollectionPool
    function withdrawERC20(ERC20 a, uint256 amount) external onlyAuthorized {
        if (a == token()) {
            require(a.balanceOf(address(this)) >= amount + tradeFee, "Too little ERC20");

            // emit event since it is the pool token
            emit TokenWithdrawal(amount);
        }

        a.safeTransfer(owner(), amount);
    }

    /// @inheritdoc CollectionPool
    function withdrawTradeFee() external override onlyOwner {
        uint256 _tradeFee = tradeFee;
        if (_tradeFee > 0) {
            tradeFee = 0;

            token().safeTransfer(msg.sender, _tradeFee);

            // emit event since it is the pool token
            emit TokenWithdrawal(_tradeFee);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import {ERC20} from "solmate/src/tokens/ERC20.sol";

import {ICurve} from "../bonding-curves/ICurve.sol";
import {ICollectionPoolFactory} from "../pools/ICollectionPoolFactory.sol";

library CollectionPoolCloner {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     *
     * During the delegate call, extra data is copied into the calldata which can then be
     * accessed by the implementation contract.
     */
    function cloneETHPool(
        address implementation,
        ICollectionPoolFactory factory,
        ICurve bondingCurve,
        IERC721 nft,
        uint8 poolType
    ) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)

            // -------------------------------------------------------------------------------------------------------------
            // CREATION (9 bytes)
            // -------------------------------------------------------------------------------------------------------------

            // creation size = 09
            // runtime size = 72
            // 60 runtime  | PUSH1 runtime (r)     | r                       | –
            // 3d          | RETURNDATASIZE        | 0 r                     | –
            // 81          | DUP2                  | r 0 r                   | –
            // 60 creation | PUSH1 creation (c)    | c r 0 r                 | –
            // 3d          | RETURNDATASIZE        | 0 c r 0 r               | –
            // 39          | CODECOPY              | 0 r                     | [0-runSize): runtime code
            // f3          | RETURN                |                         | [0-runSize): runtime code

            // -------------------------------------------------------------------------------------------------------------
            // RUNTIME (53 bytes of code + 61 bytes of extra data = 114 bytes)
            // -------------------------------------------------------------------------------------------------------------

            // extra data size = 3d
            // 3d          | RETURNDATASIZE        | 0                       | –
            // 3d          | RETURNDATASIZE        | 0 0                     | –
            // 3d          | RETURNDATASIZE        | 0 0 0                   | –
            // 3d          | RETURNDATASIZE        | 0 0 0 0                 | –
            // 36          | CALLDATASIZE          | cds 0 0 0 0             | –
            // 3d          | RETURNDATASIZE        | 0 cds 0 0 0 0           | –
            // 3d          | RETURNDATASIZE        | 0 0 cds 0 0 0 0         | –
            // 37          | CALLDATACOPY          | 0 0 0 0                 | [0, cds) = calldata
            // 60 extra    | PUSH1 extra           | extra 0 0 0 0           | [0, cds) = calldata
            // 60 0x35     | PUSH1 0x35            | 0x35 extra 0 0 0 0      | [0, cds) = calldata // 0x35 (53) is runtime size - data
            // 36          | CALLDATASIZE          | cds 0x35 extra 0 0 0 0  | [0, cds) = calldata
            // 39          | CODECOPY              | 0 0 0 0                 | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 36          | CALLDATASIZE          | cds 0 0 0 0             | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 60 extra    | PUSH1 extra           | extra cds 0 0 0 0       | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 01          | ADD                   | cds+extra 0 0 0 0       | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 3d          | RETURNDATASIZE        | 0 cds 0 0 0 0           | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 73 addr     | PUSH20 0x123…         | addr 0 cds 0 0 0 0      | [0, cds) = calldata, [cds, cds+0x35) = extraData
            mstore(
                ptr,
                hex"60_72_3d_81_60_09_3d_39_f3_3d_3d_3d_3d_36_3d_3d_37_60_3d_60_35_36_39_36_60_3d_01_3d_73_00_00_00"
            )
            mstore(add(ptr, 0x1d), shl(0x60, implementation))

            // 5a          | GAS                   | gas addr 0 cds 0 0 0 0  | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // f4          | DELEGATECALL          | success 0 0             | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 3d          | RETURNDATASIZE        | rds success 0 0         | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 3d          | RETURNDATASIZE        | rds rds success 0 0     | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 93          | SWAP4                 | 0 rds success 0 rds     | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 80          | DUP1                  | 0 0 rds success 0 rds   | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 3e          | RETURNDATACOPY        | success 0 rds           | [0, rds) = return data (there might be some irrelevant leftovers in memory [rds, cds+0x37) when rds < cds+0x37)
            // 60 0x33     | PUSH1 0x33            | 0x33 sucess 0 rds       | [0, rds) = return data
            // 57          | JUMPI                 | 0 rds                   | [0, rds) = return data
            // fd          | REVERT                | –                       | [0, rds) = return data
            // 5b          | JUMPDEST              | 0 rds                   | [0, rds) = return data
            // f3          | RETURN                | –                       | [0, rds) = return data
            mstore(
                add(ptr, 0x31),
                hex"5a_f4_3d_3d_93_80_3e_60_33_57_fd_5b_f3_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00"
            )

            // -------------------------------------------------------------------------------------------------------------
            // EXTRA DATA (61 bytes)
            // -------------------------------------------------------------------------------------------------------------

            mstore(add(ptr, 0x3e), shl(0x60, factory))
            mstore(add(ptr, 0x52), shl(0x60, bondingCurve))
            mstore(add(ptr, 0x66), shl(0x60, nft))
            mstore8(add(ptr, 0x7a), poolType)

            instance := create(0, ptr, 0x7b)
        }
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     *
     * During the delegate call, extra data is copied into the calldata which can then be
     * accessed by the implementation contract.
     */
    function cloneERC20Pool(
        address implementation,
        ICollectionPoolFactory factory,
        ICurve bondingCurve,
        IERC721 nft,
        uint8 poolType,
        ERC20 token
    ) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)

            // -------------------------------------------------------------------------------------------------------------
            // CREATION (9 bytes)
            // -------------------------------------------------------------------------------------------------------------

            // creation size = 09
            // runtime size = 86
            // 60 runtime  | PUSH1 runtime (r)     | r                       | –
            // 3d          | RETURNDATASIZE        | 0 r                     | –
            // 81          | DUP2                  | r 0 r                   | –
            // 60 creation | PUSH1 creation (c)    | c r 0 r                 | –
            // 3d          | RETURNDATASIZE        | 0 c r 0 r               | –
            // 39          | CODECOPY              | 0 r                     | [0-runSize): runtime code
            // f3          | RETURN                |                         | [0-runSize): runtime code

            // -------------------------------------------------------------------------------------------------------------
            // RUNTIME (53 bytes of code + 81 bytes of extra data = 134 bytes)
            // -------------------------------------------------------------------------------------------------------------

            // extra data size = 51
            // 3d          | RETURNDATASIZE        | 0                       | –
            // 3d          | RETURNDATASIZE        | 0 0                     | –
            // 3d          | RETURNDATASIZE        | 0 0 0                   | –
            // 3d          | RETURNDATASIZE        | 0 0 0 0                 | –
            // 36          | CALLDATASIZE          | cds 0 0 0 0             | –
            // 3d          | RETURNDATASIZE        | 0 cds 0 0 0 0           | –
            // 3d          | RETURNDATASIZE        | 0 0 cds 0 0 0 0         | –
            // 37          | CALLDATACOPY          | 0 0 0 0                 | [0, cds) = calldata
            // 60 extra    | PUSH1 extra           | extra 0 0 0 0           | [0, cds) = calldata
            // 60 0x35     | PUSH1 0x35            | 0x35 extra 0 0 0 0      | [0, cds) = calldata // 0x35 (53) is runtime size - data
            // 36          | CALLDATASIZE          | cds 0x35 extra 0 0 0 0  | [0, cds) = calldata
            // 39          | CODECOPY              | 0 0 0 0                 | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 36          | CALLDATASIZE          | cds 0 0 0 0             | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 60 extra    | PUSH1 extra           | extra cds 0 0 0 0       | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 01          | ADD                   | cds+extra 0 0 0 0       | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 3d          | RETURNDATASIZE        | 0 cds 0 0 0 0           | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 73 addr     | PUSH20 0x123…         | addr 0 cds 0 0 0 0      | [0, cds) = calldata, [cds, cds+0x35) = extraData
            mstore(
                ptr,
                hex"60_86_3d_81_60_09_3d_39_f3_3d_3d_3d_3d_36_3d_3d_37_60_51_60_35_36_39_36_60_51_01_3d_73_00_00_00"
            )
            mstore(add(ptr, 0x1d), shl(0x60, implementation))

            // 5a          | GAS                   | gas addr 0 cds 0 0 0 0  | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // f4          | DELEGATECALL          | success 0 0             | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 3d          | RETURNDATASIZE        | rds success 0 0         | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 3d          | RETURNDATASIZE        | rds rds success 0 0     | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 93          | SWAP4                 | 0 rds success 0 rds     | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 80          | DUP1                  | 0 0 rds success 0 rds   | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 3e          | RETURNDATACOPY        | success 0 rds           | [0, rds) = return data (there might be some irrelevant leftovers in memory [rds, cds+0x37) when rds < cds+0x37)
            // 60 0x33     | PUSH1 0x33            | 0x33 sucess 0 rds       | [0, rds) = return data
            // 57          | JUMPI                 | 0 rds                   | [0, rds) = return data
            // fd          | REVERT                | –                       | [0, rds) = return data
            // 5b          | JUMPDEST              | 0 rds                   | [0, rds) = return data
            // f3          | RETURN                | –                       | [0, rds) = return data
            mstore(
                add(ptr, 0x31),
                hex"5a_f4_3d_3d_93_80_3e_60_33_57_fd_5b_f3_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00"
            )

            // -------------------------------------------------------------------------------------------------------------
            // EXTRA DATA (81 bytes)
            // -------------------------------------------------------------------------------------------------------------

            mstore(add(ptr, 0x3e), shl(0x60, factory))
            mstore(add(ptr, 0x52), shl(0x60, bondingCurve))
            mstore(add(ptr, 0x66), shl(0x60, nft))
            mstore8(add(ptr, 0x7a), poolType)
            mstore(add(ptr, 0x7b), shl(0x60, token))

            instance := create(0, ptr, 0x8f)
        }
    }

    /**
     * @notice Checks if a contract is a clone of a CollectionPoolETH.
     * @dev Only checks the runtime bytecode, does not check the extra data.
     * @param factory the factory that deployed the clone
     * @param implementation the CollectionPoolETH implementation contract
     * @param query the contract to check
     * @return result True if the contract is a clone, false otherwise
     */
    function isETHPoolClone(
        address factory,
        address implementation,
        address query
    ) internal view returns (bool result) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(
                ptr,
                hex"3d_3d_3d_3d_36_3d_3d_37_60_3d_60_35_36_39_36_60_3d_01_3d_73_00_00_00_00_00_00_00_00_00_00_00_00"
            )
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(
                add(ptr, 0x28),
                hex"5a_f4_3d_3d_93_80_3e_60_33_57_fd_5b_f3_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00"
            )
            mstore(add(ptr, 0x35), shl(0x60, factory))

            // compare expected bytecode with that of the queried contract
            let other := add(ptr, 0x49)
            extcodecopy(query, other, 0, 0x49)
            result := and(
                eq(mload(ptr), mload(other)),
                and(
                    eq(mload(add(ptr, 0x20)), mload(add(other, 0x20))),
                    eq(mload(add(ptr, 0x29)), mload(add(other, 0x29)))
                )
            )
        }
    }

    /**
     * @notice Checks if a contract is a clone of a CollectionPoolERC20.
     * @dev Only checks the runtime bytecode, does not check the extra data.
     * @param implementation the CollectionPoolERC20 implementation contract
     * @param query the contract to check
     * @return result True if the contract is a clone, false otherwise
     */
    function isERC20PoolClone(
        address factory,
        address implementation,
        address query
    ) internal view returns (bool result) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(
                ptr,
                hex"3d_3d_3d_3d_36_3d_3d_37_60_51_60_35_36_39_36_60_51_01_3d_73_00_00_00_00_00_00_00_00_00_00_00_00"
            )
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(
                add(ptr, 0x28),
                hex"5a_f4_3d_3d_93_80_3e_60_33_57_fd_5b_f3_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00"
            )
            mstore(add(ptr, 0x35), shl(0x60, factory))

            // compare expected bytecode with that of the queried contract
            let other := add(ptr, 0x49)
            extcodecopy(query, other, 0, 0x49)
            result := and(
                eq(mload(ptr), mload(other)),
                and(
                    eq(mload(add(ptr, 0x20)), mload(add(other, 0x20))),
                    eq(mload(add(ptr, 0x29)), mload(add(other, 0x29)))
                )
            )
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {CollectionPoolETH} from "./CollectionPoolETH.sol";
import {CollectionPoolEnumerable} from "./CollectionPoolEnumerable.sol";
import {ICollectionPoolFactory} from "./ICollectionPoolFactory.sol";

/**
 * @title An NFT/Token pool where the NFT implements ERC721Enumerable, and the token is ETH
 * @author Collection
 */
contract CollectionPoolEnumerableETH is CollectionPoolEnumerable, CollectionPoolETH {
    /**
     * @notice Returns the CollectionPool type
     */
    function poolVariant() public pure override returns (ICollectionPoolFactory.PoolVariant) {
        return ICollectionPoolFactory.PoolVariant.ENUMERABLE_ETH;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {CollectionPoolERC20} from "./CollectionPoolERC20.sol";
import {CollectionPoolEnumerable} from "./CollectionPoolEnumerable.sol";
import {ICollectionPoolFactory} from "./ICollectionPoolFactory.sol";

/**
 * @title An NFT/Token pool where the NFT implements ERC721Enumerable, and the token is an ERC20
 * @author Collection
 */
contract CollectionPoolEnumerableERC20 is CollectionPoolEnumerable, CollectionPoolERC20 {
    /**
     * @notice Returns the CollectionPool type
     */
    function poolVariant() public pure override returns (ICollectionPoolFactory.PoolVariant) {
        return ICollectionPoolFactory.PoolVariant.ENUMERABLE_ERC20;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {CollectionPoolETH} from "../pools/CollectionPoolETH.sol";
import {CollectionPoolMissingEnumerable} from "./CollectionPoolMissingEnumerable.sol";
import {ICollectionPoolFactory} from "./ICollectionPoolFactory.sol";

contract CollectionPoolMissingEnumerableETH is CollectionPoolMissingEnumerable, CollectionPoolETH {
    function poolVariant() public pure override returns (ICollectionPoolFactory.PoolVariant) {
        return ICollectionPoolFactory.PoolVariant.MISSING_ENUMERABLE_ETH;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {CollectionPoolERC20} from "../pools/CollectionPoolERC20.sol";
import {CollectionPoolMissingEnumerable} from "./CollectionPoolMissingEnumerable.sol";
import {ICollectionPoolFactory} from "./ICollectionPoolFactory.sol";

contract CollectionPoolMissingEnumerableERC20 is CollectionPoolMissingEnumerable, CollectionPoolERC20 {
    function poolVariant() public pure override returns (ICollectionPoolFactory.PoolVariant) {
        return ICollectionPoolFactory.PoolVariant.MISSING_ENUMERABLE_ERC20;
    }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {CollectionRouter} from "../routers/CollectionRouter.sol";
import {ICollectionPool} from "./ICollectionPool.sol";
import {CollectionPool} from "./CollectionPool.sol";
import {ICollectionPoolFactory} from "./ICollectionPoolFactory.sol";

/**
 * @title An NFT/Token pool for an NFT that implements ERC721Enumerable
 * @author Collection
 */
abstract contract CollectionPoolEnumerable is CollectionPool {
    /// @inheritdoc CollectionPool
    function _selectArbitraryNFTs(IERC721 _nft, uint256 numNFTs)
        internal
        view
        override
        returns (uint256[] memory tokenIds)
    {
        tokenIds = new uint256[](numNFTs);
        // (we know NFT implements IERC721Enumerable so we just iterate)
        uint256 lastIndex = _nft.balanceOf(address(this)) - 1;
        for (uint256 i = 0; i < numNFTs;) {
            uint256 nftId = IERC721Enumerable(address(_nft)).tokenOfOwnerByIndex(address(this), lastIndex);
            tokenIds[i] = nftId;

            unchecked {
                --lastIndex;
                ++i;
            }
        }
    }

    /// @inheritdoc CollectionPool
    function _sendSpecificNFTsToRecipient(IERC721 _nft, address nftRecipient, uint256[] memory nftIds)
        internal
        override
    {
        // Send NFTs to recipient
        uint256 numNFTs = nftIds.length;
        for (uint256 i; i < numNFTs;) {
            _nft.safeTransferFrom(address(this), nftRecipient, nftIds[i]);

            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc CollectionPool
    function getAllHeldIds() external view override returns (uint256[] memory) {
        IERC721 _nft = nft();
        uint256 numNFTs = _nft.balanceOf(address(this));
        uint256[] memory ids = new uint256[](numNFTs);
        for (uint256 i; i < numNFTs;) {
            ids[i] = IERC721Enumerable(address(_nft)).tokenOfOwnerByIndex(address(this), i);

            unchecked {
                ++i;
            }
        }
        return ids;
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /// @inheritdoc ICollectionPool
    function withdrawERC721(IERC721 a, uint256[] calldata nftIds) external override onlyAuthorized {
        uint256 numNFTs = nftIds.length;
        address owner = owner();
        for (uint256 i; i < numNFTs;) {
            a.safeTransferFrom(address(this), owner, nftIds[i]);

            unchecked {
                ++i;
            }
        }

        emit NFTWithdrawal();
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {ICollectionPool} from "../pools/ICollectionPool.sol";
import {CollectionPool} from "../pools/CollectionPool.sol";
import {CollectionRouter} from "../routers/CollectionRouter.sol";

/**
 * @title An NFT/Token pool for an NFT that does not implement ERC721Enumerable
 * @author Collection
 */
abstract contract CollectionPoolMissingEnumerable is CollectionPool {
    using EnumerableSet for EnumerableSet.UintSet;

    // Used for internal ID tracking
    EnumerableSet.UintSet private idSet;

    /// @inheritdoc CollectionPool
    function _selectArbitraryNFTs(IERC721, uint256 numNFTs) internal override returns (uint256[] memory tokenIds) {
        tokenIds = new uint256[](numNFTs);
        // We're missing enumerable, so we also update the pool's own ID set
        // NOTE: We start from last index to first index to save on gas
        uint256 lastIndex = idSet.length() - 1;
        for (uint256 i; i < numNFTs;) {
            uint256 nftId = idSet.at(lastIndex);
            tokenIds[i] = nftId;
            idSet.remove(nftId);

            unchecked {
                --lastIndex;
                ++i;
            }
        }
    }

    /// @inheritdoc CollectionPool
    function _sendSpecificNFTsToRecipient(IERC721 _nft, address nftRecipient, uint256[] memory nftIds)
        internal
        override
    {
        // Send NFTs to caller
        // If missing enumerable, update pool's own ID set
        uint256 numNFTs = nftIds.length;
        for (uint256 i; i < numNFTs;) {
            _nft.safeTransferFrom(address(this), nftRecipient, nftIds[i]);
            // Remove from id set
            idSet.remove(nftIds[i]);

            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc CollectionPool
    function getAllHeldIds() external view override returns (uint256[] memory) {
        uint256 numNFTs = idSet.length();
        uint256[] memory ids = new uint256[](numNFTs);
        for (uint256 i; i < numNFTs;) {
            ids[i] = idSet.at(i);

            unchecked {
                ++i;
            }
        }
        return ids;
    }

    /**
     * @dev When safeTransfering an ERC721 in, we add ID to the idSet
     * if it's the same collection used by pool. (As it doesn't auto-track because no ERC721Enumerable)
     */
    function onERC721Received(address, address, uint256 id, bytes memory) public virtual returns (bytes4) {
        IERC721 _nft = nft();
        // If it's from the pool's NFT, add the ID to ID set
        if (msg.sender == address(_nft)) {
            idSet.add(id);
        }
        return this.onERC721Received.selector;
    }

    /// @inheritdoc ICollectionPool
    function withdrawERC721(IERC721 a, uint256[] calldata nftIds) external override onlyAuthorized {
        IERC721 _nft = nft();
        uint256 numNFTs = nftIds.length;
        address owner = owner();

        // If it's not the pool's NFT, just withdraw normally
        if (a != _nft) {
            for (uint256 i; i < numNFTs;) {
                a.safeTransferFrom(address(this), owner, nftIds[i]);

                unchecked {
                    ++i;
                }
            }
        }
        // Otherwise, withdraw and also remove the ID from the ID set
        else {
            for (uint256 i; i < numNFTs;) {
                _nft.safeTransferFrom(address(this), owner, nftIds[i]);
                idSet.remove(nftIds[i]);

                unchecked {
                    ++i;
                }
            }

            emit NFTWithdrawal();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

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
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
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
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
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

        /// @solidity memory-safe-assembly
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

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ICurve} from "../bonding-curves/ICurve.sol";
import {RewardVaultETH} from "./RewardVaultETH.sol";
import {ICollectionPoolFactory} from "../pools/ICollectionPoolFactory.sol";
import {ICollectionPool} from "../pools/ICollectionPool.sol";
import {ISortitionTreeManager} from "../tree/ISortitionTreeManager.sol";
import {ReentrancyGuard} from "../lib/ReentrancyGuard.sol";
import {RNGInterface} from "../rng/RNGInterface.sol";
import {IValidator} from "../validators/IValidator.sol";

contract RewardVaultETHDraw is ReentrancyGuard, RewardVaultETH {
    using SafeERC20 for IERC20;

    /// @notice RNG contract interface
    RNGInterface public rng;
    /// @notice RNG request ID corresponding to the Chainlink interactor, so we can look up the RNG status and result.
    uint32 public myRNGRequestId;
    uint64 public thisEpoch;

    mapping(uint64 => uint256) public epochToStartTime;
    mapping(uint64 => uint256) public epochToFinishTime;
    mapping(uint64 => uint256) public epochToRandomNumber;

    /**
     * @dev This struct is used to track the last observed amount and the time-weighted average price (TWAP) for a user's balance.
     */
    struct SimpleObservation {
        uint256 timestamp;
        uint256 lastAmount;
        uint256 twapCumSum;
        uint256 predictedEndSum; // relies on knowing epoch end in advance
    }

    // list of addresses who have interacted with this contract - necessary to get the list of all interactors
    address[] internal totalVaultInteractorList;
    mapping(address => SimpleObservation) public lastTWAPObservation;

    /**
     * @dev This enum is used to track the status of the draw for a given epoch. The possible statuses are:
     * @dev Open: The draw is currently open and users can enter.
     * @dev Closed: The draw is closed and no more entries are accepted.
     * @dev Resolved: The winners have been determined and the rewards have been distributed.
     */
    enum DrawStatus {
        Open,
        Closed,
        Resolved
    }

    DrawStatus public drawStatus;

    //////////////////////////////////////////
    // DRAW AMOUNTS
    //////////////////////////////////////////

    bytes32 private TREE_KEY;
    uint256 private constant MAX_TREE_LEAVES = 5;
    uint256 public constant MAX_REWARD_NFTS = 200;
    uint256 public constant MAX_PRIZE_WINNERS_PER_EPOCH = 500;
    address private constant DUMMY_ADDRESS = address(0);
    ISortitionTreeManager public treeManager;

    /**
     * @dev This struct is used to store information about a non-fungible token (NFT) that is being awarded as a prize.
     */
    struct NFTData {
        IERC721 nftAddress;
        uint256 nftID;
    }

    struct PrizeSet {
        // ERC20 tokens to reward
        IERC20[] erc20RewardTokens;
        // ERC721 tokens to reward
        IERC721[] erc721RewardTokens;
        uint256 numERC721Prizes;
        uint256 prizePerWinner;
    }

    /**
     * @dev This struct is used to store information about the winners for a given epoch. It includes the number of draw winners, the number of prizes per winner, and the remainder.
     */
    struct WinnerConfig {
        uint256 numberOfDrawWinners;
        uint256 numberOfPrizesPerWinner;
        uint256 remainder;
    }
    // Mappings of epoch to prize data

    mapping(uint64 => PrizeSet) public epochPrizeSets;
    mapping(uint64 => mapping(IERC20 => uint256)) public epochERC20PrizeAmounts;
    mapping(uint64 => mapping(IERC721 => bool)) public epochERC721Collections;
    /**
     * @dev This mapping is used to store information about the specific NFTs that will be awarded as prizes for each epoch.
     */
    mapping(uint64 => mapping(uint256 => NFTData)) public epochERC721PrizeIdsData;
    mapping(uint64 => WinnerConfig) public epochWinnerConfigs;

    mapping(uint64 => mapping(address => uint256)) public epochUserERC20NumWinnerEntries; // denominator is epochWinnerConfigs[epoch].numberOfDrawWinners

    // NFT prizes
    /**
     * @dev epoch => user => `index_arr`, where `address` is awardable
     * `epochERC721PrizeIdsData[index * numberOfPrizesPerWinner + 1]`
     * to
     * `epochERC721PrizeIdsData[(index + 1) * numberOfPrizesPerWinner]`
     * for all `index` in `index_arr`
     */
    mapping(uint64 => mapping(address => uint256[])) public epochUserPrizeStartIndices;

    // Both ERC20 and ERC721 prizes
    mapping(uint64 => mapping(address => bool)) public isPrizeClaimable;

    //////////////////////////////////////////
    // EVENTS
    //////////////////////////////////////////

    event DrawOpen(uint64 epoch);
    event DrawClosed(uint64 epoch);
    event PrizesAdded(
        uint64 indexed epoch,
        IERC721[] prizeNftCollections,
        uint256[] prizeNftIds,
        IERC20[] prizeTokens,
        uint256[] prizeAmounts,
        uint256 indexed startTime,
        uint256 indexed endTime
    );
    event PrizesPerWinnerUpdated(uint64 indexed epoch, uint256 numPrizesPerWinner);
    event DrawResolved(uint64 indexed epoch, address[] winners);
    event Claimed(uint64 indexed epoch, address user);

    //////////////////////////////////////////
    // ERRORS
    //////////////////////////////////////////
    error BadEpochZeroInitalization();
    error BadStartTime();
    error CallerNotDeployer();
    error IncorrectDrawStatus();
    error NoClaimableShare();
    error RNGRequestIncomplete();

    constructor() {
        _disableInitializers();
    }

    /**
     * @dev - this is called by the factory.
     * @param _protocolOwner - the owner of the protocol
     * @param _deployer - the vault deployer's address
     * @param _lpToken - Collectionswap deployment address
     * @param _validator - the validator contract address
     * @param _nft - the NFT contract address
     * @param _bondingCurve - the bonding curve contract address
     * @param _curveParams - the bonding curve parameters
     * @param _fee - the fee amount to incentivize
     * @param _rewardTokens - the reward token addresses
     * @param _rewardRates - the reward rates. Reward rates is in amount per second
     * @param _rewardStartTime - the reward start time (note that this can be different from the draw start time)
     * @param _rewardPeriodFinish - the reward period finish time
     * @param _rng - RNG contract address
     * @param _additionalERC20DrawPrize - additional ERC20 prize to add to the draw, list
     * @param _additionalERC20DrawPrizeAmounts - additional ERC20 prize amount to add to the draw, list. NB: Note that this is NOT divided per second, unlike the _rewardRates
     * @param _nftCollectionsPrize - additional ERC721 prize to add to the draw, list
     * @param _nftIdsPrize - additional ERC721 prize ID to add to the draw, list
     * @param _prizesPerWinner - number of ERC721 prizes per winner
     * @param _drawStartTime - the start time of draw
     * @param _drawPeriodFinish - the end time of draw
     *
     */
    function initialize(
        address _protocolOwner,
        address _deployer,
        ICollectionPoolFactory _lpToken,
        IValidator _validator,
        IERC721 _nft,
        address _bondingCurve,
        ICurve.Params calldata _curveParams,
        uint96 _fee,
        uint256 _royaltyNumerator,
        bytes32 _tokenIDFilterRoot,
        IERC20[] calldata _rewardTokens,
        uint256[] calldata _rewardRates,
        uint256 _rewardStartTime,
        uint256 _rewardPeriodFinish,
        RNGInterface _rng,
        IERC20[] calldata _additionalERC20DrawPrize,
        uint256[] calldata _additionalERC20DrawPrizeAmounts,
        IERC721[] calldata _nftCollectionsPrize,
        uint256[] calldata _nftIdsPrize,
        uint256 _prizesPerWinner,
        uint256 _drawStartTime,
        uint256 _drawPeriodFinish,
        ISortitionTreeManager _treeManager
    ) external {
        __ReentrancyGuard_init();

        super.initialize({
            _protocolOwner: _protocolOwner,
            _deployer: _deployer,
            _lpToken: _lpToken,
            _validator: _validator,
            _nft: _nft,
            _bondingCurve: _bondingCurve,
            _curveParams: _curveParams,
            _fee: _fee,
            _royaltyNumerator: _royaltyNumerator,
            _tokenIDFilterRoot: _tokenIDFilterRoot,
            _rewardTokens: _rewardTokens,
            _rewardRates: _rewardRates,
            _startTime: _rewardStartTime,
            _periodFinish: _rewardPeriodFinish
        });

        LOCK_TIME = 90 days;

        rng = _rng;
        TREE_KEY = keccak256(abi.encodePacked(uint256(1)));
        treeManager = _treeManager;
        treeManager.createTree(TREE_KEY, MAX_TREE_LEAVES);

        // Ensure that there is always a non-zero initial stake.
        // This is to prevent the sortition tree from being empty.
        // Can be anyone, have set to DUMMY_ADDRESS, soft guarantee of not zeroing out
        // draw stake midway (stake then unstake)
        bytes32 _ID = addressToBytes32(DUMMY_ADDRESS);
        treeManager.set(TREE_KEY, 1, _ID);

        // thisEpoch is incremented in function below
        _addNewPrizeEpoch({
            _nftCollectionsPrize: _nftCollectionsPrize,
            _nftIdsPrize: _nftIdsPrize,
            _prizesPerWinner: _prizesPerWinner,
            _erc20Prize: _additionalERC20DrawPrize,
            _erc20PrizeAmounts: _additionalERC20DrawPrizeAmounts,
            _drawStartTime: _drawStartTime,
            _drawPeriodFinish: _drawPeriodFinish,
            _callerIsDeployer: false,
            _epoch: thisEpoch
        });
    }

    function _onlyDeployer() internal view {
        if (msg.sender != deployer) revert CallerNotDeployer();
    }

    /**
     * @dev - add ERC721 prizes and / or ERC20 prizes to the prize set
     * any mutation functions to prize sets should not permit epoch parameterization
     * @dev - Only callable by deployer
     * @dev - Specify zero drawStartTime to add during an epoch, else adding after an epoch
     */
    function addNewPrizes(
        IERC721[] calldata _nftCollectionsPrize,
        uint256[] calldata _nftIdsPrize,
        IERC20[] calldata _erc20Prize,
        uint256[] calldata _erc20PrizeAmounts,
        uint256 _prizesPerWinner,
        uint256 _drawStartTime,
        uint256 _drawPeriodFinish
    ) external {
        _onlyDeployer();
        _addNewPrizeEpoch({
            _nftCollectionsPrize: _nftCollectionsPrize,
            _nftIdsPrize: _nftIdsPrize,
            _erc20Prize: _erc20Prize,
            _erc20PrizeAmounts: _erc20PrizeAmounts,
            _prizesPerWinner: _prizesPerWinner,
            _drawStartTime: _drawStartTime,
            _drawPeriodFinish: _drawPeriodFinish,
            _callerIsDeployer: true,
            _epoch: thisEpoch
        });

        // Add after epoch
        // fast forward sortition tree
        if (_drawStartTime != 0) recalcSortitionTreesEpochStart();
    }

    /**
     * @dev - internal method for transferring and adding ERC721 and ERC20 prizes to the prize set.
     * @dev - Factory has a special-workflow for not transferring as it is easier to initialize state and then transfer tokens in.
     * @dev - workflow 1: call with non-zero drawStartTime to add a new epoch.
     * @dev - workflow 2: call with zero drawStartTime to add prizes during the current epoch.
     * @dev - NB: _drawStartTime and _drawPeriodFinish are potentially different from the rewards start and end time. (draw and rewards can potentially run on different timers)
     *
     */
    function _addNewPrizeEpoch(
        IERC721[] calldata _nftCollectionsPrize,
        uint256[] calldata _nftIdsPrize,
        IERC20[] calldata _erc20Prize,
        uint256[] calldata _erc20PrizeAmounts,
        uint256 _prizesPerWinner,
        uint256 _drawStartTime,
        uint256 _drawPeriodFinish,
        bool _callerIsDeployer,
        uint64 _epoch
    ) internal nonReentrant {
        uint256 numNfts = _nftCollectionsPrize.length;

        /////////////////////////////
        /// UPDATES FOR NEW EPOCH ///
        /////////////////////////////
        if (_drawStartTime != 0) {
            // ensure that current epoch has been resolved
            // excludes base case of _epoch == 0 (uninitialized)
            if (_epoch != 0) if (drawStatus != DrawStatus.Resolved) revert IncorrectDrawStatus();
            if (_drawStartTime <= block.timestamp) revert BadStartTime();
            if (_drawPeriodFinish <= _drawStartTime) revert BadEndTime();

            // update thisEpoch storage variable
            // and increment _epoch to new epoch
            thisEpoch = ++_epoch;

            // initialize prize set for new epoch
            _initPrizeSet(_epoch);

            // set new epoch times
            epochToStartTime[_epoch] = _drawStartTime;
            epochToFinishTime[_epoch] = _drawPeriodFinish;

            // update reward sweep time if it will exceed current reward sweep time
            uint256 newRewardSweepTime = _drawPeriodFinish + LOCK_TIME;
            if (rewardSweepTime < newRewardSweepTime) rewardSweepTime = newRewardSweepTime;

            drawStatus = DrawStatus.Open;
            emit DrawOpen(_epoch);
        } else {
            if (_epoch != 0) {
                // when adding to an existing epoch,
                // require that the draw is not resolved
                if (drawStatus == DrawStatus.Resolved) revert IncorrectDrawStatus();
            } else {
                // If epoch is zero (initialization),
                // We assume the project is only using the reward distribution portion initially,
                // and would use the draw functionality in the future
                // Hence, we check that no rewards are being distributed
                if (numNfts != 0 || _erc20Prize.length != 0) revert BadEpochZeroInitalization();
            }
        }

        ////////////////////////////
        /// HANDLING NFT PRIZES  ///
        ////////////////////////////
        if (numNfts != _nftIdsPrize.length) revert LengthMismatch();

        PrizeSet storage prizeSet = epochPrizeSets[_epoch];
        // index for appending to existing number of NFTs
        uint256 prizeIdIndex = prizeSet.numERC721Prizes;
        if (prizeIdIndex + numNfts > MAX_REWARD_NFTS) revert LengthLimitExceeded();
        // iterate through each nft in prizePool.nftCollections and transfer to this contract if caller is deployer
        for (uint256 i; i < numNfts; ++i) {
            IERC721 myCollAdd = (_nftCollectionsPrize[i]);

            if (!epochERC721Collections[_epoch][myCollAdd]) {
                // new collection for this epoch
                // check if it supports ERC721
                if (!_nftCollectionsPrize[i].supportsInterface(0x80ac58cd)) revert NFTNotERC721();
                epochERC721Collections[_epoch][myCollAdd] = true;
                prizeSet.erc721RewardTokens.push(myCollAdd);
            }
            // @dev: only need transfer NFTs in if caller is deployer
            if (_callerIsDeployer) {
                _nftCollectionsPrize[i].safeTransferFrom(msg.sender, address(this), _nftIdsPrize[i]);
            }
            epochERC721PrizeIdsData[_epoch][++prizeIdIndex] = NFTData(myCollAdd, _nftIdsPrize[i]);
        }
        // update only if numNfts is non-zero
        if (numNfts != 0) {
            prizeSet.numERC721Prizes = prizeIdIndex;
            _setPrizePerWinner(prizeSet, _prizesPerWinner);
        }

        /////////////////////////////
        /// HANDLING ERC20 PRIZES ///
        /////////////////////////////
        if (_erc20Prize.length != _erc20PrizeAmounts.length) revert LengthMismatch();

        // iterate through each ERC20 token and transfer to this contract
        for (uint256 i; i < _erc20Prize.length; ++i) {
            if (_erc20PrizeAmounts[i] == 0) revert ZeroRewardRate();
            // @dev: only need transfer tokens in if caller is deployer
            if (_callerIsDeployer) {
                _erc20Prize[i].safeTransferFrom(msg.sender, address(this), _erc20PrizeAmounts[i]);
            }

            IERC20 myCollAdd = _erc20Prize[i];
            uint256 epochAmount = epochERC20PrizeAmounts[_epoch][myCollAdd];
            if (epochAmount == 0) {
                // not encountered before
                prizeSet.erc20RewardTokens.push(myCollAdd);
                // ensure no. of ERC20 tokens don't exceed MAX_REWARD_TOKENS
                if (prizeSet.erc20RewardTokens.length > MAX_REWARD_TOKENS) revert LengthLimitExceeded();
            }
            epochERC20PrizeAmounts[_epoch][myCollAdd] = epochAmount + _erc20PrizeAmounts[i];
        }

        emit PrizesAdded(
            _epoch,
            _nftCollectionsPrize,
            _nftIdsPrize,
            _erc20Prize,
            _erc20PrizeAmounts,
            _drawStartTime,
            _drawPeriodFinish
            );
    }

    /**
     * @notice as sweep time may be updated by both the draw and reward functions, we have defensive logic to ensure it is set to the maximum of the two
     */
    function rechargeRewardVault(
        IERC20[] calldata inputRewardTokens,
        uint256[] calldata inputRewardAmounts,
        uint256 _newPeriodFinish
    ) public override {
        uint256 currentRewardSweepTime = rewardSweepTime;
        // sweep time gets updated to _newPeriodFinish + LOCK_TIME
        super.rechargeRewardVault(inputRewardTokens, inputRewardAmounts, _newPeriodFinish);
        // reset to currentRewardSweepTime if new sweep time is shorter
        // ie. rewardSweepTime should always be the maximum of its current and updated value
        if (rewardSweepTime < currentRewardSweepTime) rewardSweepTime = currentRewardSweepTime;
    }

    /**
     * @dev - initializes prize set for new epoch. Callable internally only after epoch has been incremented.
     *
     */
    function _initPrizeSet(uint64 epoch) internal {
        PrizeSet memory prizeSet;
        prizeSet.prizePerWinner = 1;
        epochPrizeSets[epoch] = prizeSet;
    }

    /**
     * @dev - O(1) lookup for previous interaction
     *
     */
    function firstTimeUser(address user) public view returns (bool) {
        return lastTWAPObservation[user].timestamp == 0;
    }

    /**
     * @notice Fresh state for the sortition tree at the start of a new epoch.
     * prune interactors with 0 `lastAmount` as they are effectively irrelevant
     * @dev - As we are taking a TWAP and using a persistent sortition tree, we
     * need to maintain a list of addresses who have interacted with the vault
     * in the past, and recalc the TWAP for each epoch. This is done by the
     * deployer, and is part of the cost of recharging. The interactor list is
     * pruned upon calling this function.
     */
    function recalcSortitionTreesEpochStart() internal {
        // lastObservationTimestamp is arbitrarily set as 0
        // because it is only used for calculation of timeElapsed
        // which is redundant in this function
        (, uint256 amountTimeRemainingToVaultEnd) = getTimeProgressInEpoch(block.timestamp, 0);

        // Recalculate sortition trees for everything in vaultInteractorList,
        // for the new periodFinish. Use --i because (0 - 1) underflows to
        // uintmax which causes a revert
        for (uint256 i = totalVaultInteractorList.length; i > 0;) {
            --i;

            address vaultInteractor = totalVaultInteractorList[i];
            SimpleObservation storage lastObservation = lastTWAPObservation[vaultInteractor];

            uint256 sortitionValue;
            // `lastObservation.lastAmount` remains the same
            if (lastObservation.lastAmount == 0) {
                // Delete the vault interactor from storage if they have 0 balance
                // (this is why we iterate in reverse order).
                totalVaultInteractorList[i] = totalVaultInteractorList[totalVaultInteractorList.length - 1];
                totalVaultInteractorList.pop();

                // Delete vault interactor from `lastTWAPObservation`
                delete lastTWAPObservation[vaultInteractor];
            } else {
                lastObservation.timestamp = block.timestamp;
                lastObservation.twapCumSum = 0;
                lastObservation.predictedEndSum = lastObservation.lastAmount * amountTimeRemainingToVaultEnd;
                sortitionValue = lastObservation.predictedEndSum;
            }

            // Update the sortition tree. Sortition tree library deletes 0
            // entries for us
            bytes32 _ID = addressToBytes32(vaultInteractor);
            treeManager.set(TREE_KEY, sortitionValue, _ID);
        }
    }

    /**
     * @notice Stake an LP token
     * @param tokenId The tokenId of the LP token to stake
     * @return amount The amount of reward token minted as a result
     * @dev - Maintain the new expected TWAP balance for the user.
     */
    function stake(uint256 tokenId) public override returns (uint256 amount) {
        if (firstTimeUser(msg.sender)) totalVaultInteractorList.push(msg.sender);
        amount = super.stake(tokenId);
        updateSortitionStake(msg.sender, amount, true, (drawStatus == DrawStatus.Open));
    }

    /**
     * @dev - if draw is open, directly calculate the expected TWAP balance for the user.
     */
    function burn(uint256 tokenId) internal override returns (uint256 amount) {
        amount = super.burn(tokenId);
        updateSortitionStake(msg.sender, amount, false, (drawStatus == DrawStatus.Open));
    }

    /**
     * @param eventTimestamp specified timestamp of when to calculate progress from
     * @param lastObservationTimestamp timestamp at which the last observation for the user was made
     * @return timeElapsed the effective time elapsed during thisEpoch
     * @return timeRemaining the remaining amount of usable time to extend on the current TWAP cumsum.
     * This is to calculate the expected TWAP at drawFinish so that
     * we don't have to iterate through all addresses to get the right epoch-end weighted stake.
     * We check that (A) eventTimestamp is less than drawFinish.
     * And it is always bounded by the drawFinish - start time, even if the vault hasn't started.
     */
    function getTimeProgressInEpoch(uint256 eventTimestamp, uint256 lastObservationTimestamp)
        public
        view
        returns (uint256 timeElapsed, uint256 timeRemaining)
    {
        uint64 _epoch = thisEpoch;
        uint256 _drawStart = epochToStartTime[_epoch];
        uint256 _drawFinish = epochToFinishTime[_epoch];

        if (eventTimestamp < _drawStart) {
            // draw has not commenced:
            // timeElapsed should be 0
            // timeRemaining should be the full draw duration
            return (0, _drawFinish - _drawStart);
        }

        timeElapsed = Math.min(_drawFinish, eventTimestamp) - Math.max(_drawStart, lastObservationTimestamp);

        timeRemaining = eventTimestamp > _drawFinish ? 0 : _drawFinish - eventTimestamp;
    }

    /**
     * @dev - updateSortitionStake (updates Sortition stake and TWAP). This is called either when a user stakes/burns, but sortition tree is modified only when draw is open
     */
    function updateSortitionStake(address _staker, uint256 _amount, bool isIncrement, bool modifySortition) internal {
        SimpleObservation storage lastObservation = lastTWAPObservation[_staker];
        (uint256 timeElapsed, uint256 amountTimeRemainingToVaultEnd) =
            getTimeProgressInEpoch(block.timestamp, lastObservation.timestamp);

        // update lastObservation parameters
        // increment cumulative sum given effective time elapsed
        lastObservation.twapCumSum += timeElapsed * lastObservation.lastAmount;

        lastObservation.lastAmount =
            isIncrement ? lastObservation.lastAmount + _amount : lastObservation.lastAmount - _amount;

        lastObservation.timestamp = block.timestamp;
        lastObservation.predictedEndSum =
            lastObservation.twapCumSum + (amountTimeRemainingToVaultEnd * lastObservation.lastAmount);

        if (modifySortition) {
            bytes32 _ID = addressToBytes32(_staker);
            treeManager.set(TREE_KEY, lastObservation.predictedEndSum, _ID);
        }
    }

    /**
     * @dev - get numerator/denominator for chances of winning
     */
    function viewChanceOfDraw(address _staker)
        external
        view
        returns (uint256 chanceNumerator, uint256 chanceDenominator)
    {
        bytes32 _treeKey = TREE_KEY;
        chanceNumerator = treeManager.stakeOf(_treeKey, addressToBytes32(_staker));
        chanceDenominator = treeManager.total(_treeKey);
    }

    /**
     * @dev - get number of winners and number of prizes per winner
     */
    function getDrawDistribution(uint64 epoch)
        public
        view
        returns (bool hasNFTPrizes, uint256 numberOfDrawWinners, uint256 numberOfPrizesPerWinner, uint256 remainder)
    {
        numberOfPrizesPerWinner = epochPrizeSets[epoch].prizePerWinner;
        uint256 numPrizes = epochPrizeSets[epoch].numERC721Prizes;
        if (numPrizes == 0) {
            // ERC20-only-draw: assumed to be only ERC20 prize: numberOfPrizesPerWinner = number of winners
            return (false, numberOfPrizesPerWinner, numberOfPrizesPerWinner, 0);
        }
        hasNFTPrizes = true;

        // numberOfPrizesPerWinner has been checked to be <= numPrizes
        // ensuring at least 1 winner
        numberOfDrawWinners = numPrizes / numberOfPrizesPerWinner;
        if (numberOfDrawWinners > MAX_PRIZE_WINNERS_PER_EPOCH) numberOfDrawWinners = MAX_PRIZE_WINNERS_PER_EPOCH;
        numberOfPrizesPerWinner = numPrizes / numberOfDrawWinners;
        remainder = numPrizes % numberOfDrawWinners;
    }

    /// @dev If there are no NFTs (ie. only ERC20 draw), _prizePerWinner will be treated as the number of winners
    function setPrizePerWinner(uint256 _prizePerWinner) external {
        _onlyDeployer();
        // not necessary to check drawStatus because winner config will be saved upon draw resolution: resolveDrawResults()
        _setPrizePerWinner(epochPrizeSets[thisEpoch], _prizePerWinner);
    }

    function _setPrizePerWinner(PrizeSet storage prizeSet, uint256 _prizePerWinner) internal {
        // if there are ERC721 prizes, ensure that the _prizePerWinner is within limit
        if (prizeSet.numERC721Prizes != 0) {
            if (_prizePerWinner > prizeSet.numERC721Prizes) revert LengthLimitExceeded();
        } else {
            // ERC20-only-draw: uses prizePerWinner as subdivisions of total ERC20 prize and as stand-in for number of winners. Do check here.
            if (_prizePerWinner > MAX_PRIZE_WINNERS_PER_EPOCH) revert LengthLimitExceeded();
        }

        if (_prizePerWinner == 0) revert ZeroRewardRate();
        prizeSet.prizePerWinner = _prizePerWinner;
        emit PrizesPerWinnerUpdated(thisEpoch, _prizePerWinner);
    }

    /**
     * @dev - allows draw to be closed once the periodFinish has passed. Can be called by anyone (not just deployer) - in case deployer goes missing
     */
    function closeDraw() external returns (uint32 requestId, uint32 lockBlock) {
        if (drawStatus != DrawStatus.Open) revert IncorrectDrawStatus();
        if (block.timestamp < epochToFinishTime[thisEpoch]) revert TooEarly();
        drawStatus = DrawStatus.Closed;
        (requestId, lockBlock) = rng.requestRandomNumber();
        myRNGRequestId = requestId;

        emit DrawClosed(thisEpoch);
    }

    /**
     * @dev - pseudorandom number generation from a verifiably random starting point.
     */
    function getWinner(uint256 randomNumber, uint256 iteration) private view returns (address winner) {
        // uint256 randomNumber = epochToRandomNumber[thisEpoch];
        uint256 i;
        bytes32 _treeKey = TREE_KEY;
        while (true) {
            uint256 finalRandom = uint256(keccak256(abi.encodePacked(randomNumber, iteration, i)));
            winner = bytes32ToAddress(treeManager.draw(_treeKey, finalRandom));
            if (winner != DUMMY_ADDRESS) {
                return winner;
            }
            ++i;
        }
    }

    /**
     * @dev - resolvesDrawResults. This can be called by anyone (not just deployer) - in case deployer goes missing. Sets the winners and their start indices, taking reference from NFT address x ID tuples
     */
    function resolveDrawResults() external {
        // cache storage read
        uint32 _myRNGRequestId = myRNGRequestId;
        if (drawStatus != DrawStatus.Closed) revert IncorrectDrawStatus();
        if (!rng.isRequestComplete(_myRNGRequestId)) revert RNGRequestIncomplete();
        uint64 _epoch = thisEpoch;
        // set drawStatus to resolved
        drawStatus = DrawStatus.Resolved;
        uint256 randomNum = rng.randomNumber(_myRNGRequestId);
        epochToRandomNumber[_epoch] = randomNum;

        // prize Distribution
        (bool hasNFTPrizes, uint256 numberOfDrawWinners, uint256 numberOfPrizesPerWinner, uint256 remainder) =
            getDrawDistribution(_epoch);
        epochWinnerConfigs[_epoch] = WinnerConfig(numberOfDrawWinners, numberOfPrizesPerWinner, remainder);

        // iterate through the Number of Winners
        uint256 denominator = treeManager.total(TREE_KEY);
        bool noDrawParticipants = (denominator == 1);
        // winner list may contain duplicate addresses
        // emitted in the WinnersDrawn event but not stored
        address[] memory winnerList = new address[](numberOfDrawWinners);
        for (uint256 i; i < numberOfDrawWinners; ++i) {
            // get the winner
            address winner = noDrawParticipants ? deployer : getWinner(randomNum, i);

            //////////////////////////////////////
            // NFT amount
            //////////////////////////////////////
            if (hasNFTPrizes) {
                epochUserPrizeStartIndices[_epoch][winner].push(i);
            }

            // set claimable status
            if (!isPrizeClaimable[_epoch][winner]) {
                isPrizeClaimable[_epoch][winner] = true;
            }

            // save in winner list
            winnerList[i] = winner;

            //////////////////////////////////////
            // ERC20 amount
            //////////////////////////////////////
            epochUserERC20NumWinnerEntries[_epoch][winner] += 1;
        }

        emit DrawResolved(_epoch, winnerList);
    }

    /**
     * @dev - Claims your share of the prize per epoch. Takes cue from the number of ERC721 tokens, first-class prizes. ERC20 tokens distribution are determined from ERC-721 tokens
     */
    function claimMyShare(uint64 epoch) public {
        if (!isPrizeClaimable[epoch][msg.sender]) revert NoClaimableShare();
        // blocks re-entrancy for the same epoch
        isPrizeClaimable[epoch][msg.sender] = false;

        // NFTs
        uint256[] memory startIndices = epochUserPrizeStartIndices[epoch][msg.sender];
        uint256 numberOfPrizesPerWinner = epochWinnerConfigs[epoch].numberOfPrizesPerWinner;

        // Award each winner N := numberOfPrizesPerWinner NFTs
        // winner 1 would be awarded NFTs of prize indices 1 to N
        // winner 2 would be awarded NFTs of prize indices N+1 to 2N
        // etc.
        uint256 prizeIndex;
        for (uint256 i; i < startIndices.length; ++i) {
            prizeIndex = startIndices[i] * numberOfPrizesPerWinner;
            for (uint256 j; j < numberOfPrizesPerWinner; ++j) {
                // starting prize index is 1-indexed, not 0-indexed
                // hence, we use the prefix increment so that value after increment is returned and used
                NFTData storage mytuple = epochERC721PrizeIdsData[epoch][++prizeIndex];
                mytuple.nftAddress.safeTransferFrom(address(this), msg.sender, mytuple.nftID);
            }
        }

        // ERC20s
        uint256 numerator = epochUserERC20NumWinnerEntries[epoch][msg.sender];
        /**
         * @dev numberOfDrawWinners is the number of winners with duplicates
         */
        uint256 denominator = epochWinnerConfigs[epoch].numberOfDrawWinners;
        IERC20[] memory erc20RewardTokens = epochPrizeSets[epoch].erc20RewardTokens;

        for (uint256 i; i < erc20RewardTokens.length; ++i) {
            IERC20 token = erc20RewardTokens[i];
            uint256 totalReward = epochERC20PrizeAmounts[epoch][token];
            uint256 userReward = (totalReward * numerator) / denominator;
            token.safeTransfer(msg.sender, userReward);
        }
        emit Claimed(epoch, msg.sender);
    }

    /**
     * @dev - Claims your share of the prize for specified epochs
     */
    function claimMySharesMultiple(uint64[] calldata epochs) external {
        for (uint256 i; i < epochs.length; ++i) {
            claimMyShare(epochs[i]);
        }
    }

    /**
     * @dev - Sweeps specified unclaimed NFTs, but only after rewardSweepTime
     * Note that remainder NFTs count from the last index, and that prizeData is 1-indexed
     * Eg. 10 NFT prizes, 4 winners for the draw = remainder of 2 NFTs
     * Specified NFT ids should be 9 and 10
     */
    function sweepUnclaimedNfts(uint64 epoch, uint256[] calldata prizeIndices) external {
        _onlyDeployer();
        if (block.timestamp < rewardSweepTime) revert TooEarly();
        for (uint256 i; i < prizeIndices.length; ++i) {
            NFTData storage nftData = epochERC721PrizeIdsData[epoch][prizeIndices[i]];
            nftData.nftAddress.safeTransferFrom(address(this), msg.sender, nftData.nftID);
        }
    }

    /**
     * @dev - Helper functions
     */

    function addressToBytes32(address _address) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_address)));
    }

    function bytes32ToAddress(bytes32 _bytes32) internal pure returns (address) {
        return address(uint160(uint256(_bytes32)));
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {ICurve} from "../bonding-curves/ICurve.sol";
import {ICollectionPoolFactory} from "../pools/ICollectionPoolFactory.sol";
import {ICollectionPool} from "../pools/ICollectionPool.sol";
import {IValidator} from "../validators/IValidator.sol";

contract RewardVaultETH is IERC721Receiver, Initializable {
    using SafeERC20 for IERC20;

    struct LPTokenInfo {
        uint256 amount0;
        uint256 amount1;
        uint256 amount;
        address owner;
    }

    /// @dev The number of NFTs in the pool
    uint128 private reserve0; // uses single storage slot, accessible via getReserves
    /// @dev The amount of ETH in the pool
    uint128 private reserve1; // uses single storage slot, accessible via getReserves

    address protocolOwner;
    address deployer;
    ICollectionPoolFactory public lpToken;
    IValidator public validator;
    IERC721 nft;
    ICurve.Params curveParams;
    address bondingCurve;
    uint96 fee;
    uint256 royaltyNumerator;
    bytes32 tokenIDFilterRoot;

    uint256 public constant MAX_REWARD_TOKENS = 5;
    uint256 public LOCK_TIME;

    /// @dev The total number of tokens minted
    uint256 private _totalSupply;
    mapping(address => uint256) internal _balances;
    /// @dev maps from tokenId to pool LPToken information
    mapping(uint256 => LPTokenInfo) public lpTokenInfo;

    IERC20[] public rewardTokens;
    mapping(IERC20 => bool) public rewardTokenValid;

    uint256 public periodFinish;
    uint256 public rewardSweepTime;
    /// @dev maps from ERC20 token to the reward amount / duration of period
    mapping(IERC20 => uint256) public rewardRates;
    uint256 public lastUpdateTime;
    /**
     * @dev maps from ERC20 token to the reward amount accumulated per unit of
     * reward token
     */
    mapping(IERC20 => uint256) public rewardPerTokenStored;
    mapping(IERC20 => mapping(address => uint256)) public userRewardPerTokenPaid;
    mapping(IERC20 => mapping(address => uint256)) public rewards;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 tokenId, uint256 amount);
    event Withdrawn(address indexed user, uint256 tokenId, uint256 amount);
    event RewardPaid(IERC20 indexed rewardToken, address indexed user, uint256 reward);
    event RewardSwept();
    event RewardVaultRecharged(IERC20[] rewardTokens, uint256[] rewards, uint256 startTime, uint256 endTime);

    //////////////////////////////////////////
    // ERRORS
    //////////////////////////////////////////
    error BadEndTime();
    error BalanceOverflow();
    error CallerNotEOA();
    error LengthLimitExceeded();
    error LengthMismatch();
    error MissingExistingTokens();
    error NFTNotERC721();
    error NotTwoSidedLP();
    error PoolMismatch();
    error RepeatedToken();
    error RewardsOngoing();
    error TokenMismatch();
    error TooEarly();
    error Unauthorized();
    error ZeroRewardRate();

    modifier updateReward(address account) {
        // skip update after rewards program starts
        // cannot include equality because
        // multiple accounts can perform actions in the same block
        // and we have to update account's rewards and userRewardPerTokenPaid values
        if (block.timestamp < lastUpdateTime) {
            _;
            return;
        }

        _applyRewardUpdate(account);
        _;
    }

    function _applyRewardUpdate(address account) internal {
        uint256 rewardTokensLength = rewardTokens.length;
        // lastUpdateTime is set to startTime in constructor
        if (block.timestamp > lastUpdateTime) {
            for (uint256 i; i < rewardTokensLength;) {
                IERC20 rewardToken = rewardTokens[i];
                rewardPerTokenStored[rewardToken] = rewardPerToken(rewardToken);
                unchecked {
                    ++i;
                }
            }
            lastUpdateTime = lastTimeRewardApplicable();
        }
        if (account != address(0)) {
            for (uint256 i; i < rewardTokensLength;) {
                IERC20 rewardToken = rewardTokens[i];
                rewards[rewardToken][account] = earned(account, rewardToken);
                userRewardPerTokenPaid[rewardToken][account] = rewardPerTokenStored[rewardToken];
                unchecked {
                    ++i;
                }
            }
        }
    }

    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _protocolOwner,
        address _deployer,
        ICollectionPoolFactory _lpToken,
        IValidator _validator,
        IERC721 _nft,
        address _bondingCurve,
        ICurve.Params calldata _curveParams,
        uint96 _fee,
        uint256 _royaltyNumerator,
        bytes32 _tokenIDFilterRoot,
        IERC20[] calldata _rewardTokens,
        uint256[] calldata _rewardRates,
        uint256 _startTime,
        uint256 _periodFinish
    ) public initializer {
        protocolOwner = _protocolOwner;
        LOCK_TIME = 30 days;
        if (!_nft.supportsInterface(0x80ac58cd)) revert NFTNotERC721(); // check if it supports ERC721
        deployer = _deployer;
        lpToken = _lpToken;
        validator = _validator;
        nft = _nft;
        bondingCurve = _bondingCurve;
        curveParams = _curveParams;
        tokenIDFilterRoot = _tokenIDFilterRoot;
        fee = _fee;
        royaltyNumerator = _royaltyNumerator;
        rewardTokens = _rewardTokens;
        unchecked {
            for (uint256 i; i < rewardTokens.length; ++i) {
                // ensure reward token hasn't been added yet
                if (rewardTokenValid[_rewardTokens[i]]) revert RepeatedToken();
                rewardRates[_rewardTokens[i]] = _rewardRates[i];
                rewardTokenValid[_rewardTokens[i]] = true;
            }
        }
        lastUpdateTime = _startTime == 0 ? block.timestamp : _startTime;
        periodFinish = _periodFinish;
        rewardSweepTime = _periodFinish + LOCK_TIME;
    }

    /**
     * @notice Add ERC20 tokens to the pool and set the `newPeriodFinish` value of
     * the pool
     *
     * @dev new reward tokens are to be appended to inputRewardTokens
     *
     * @param inputRewardTokens An array of ERC20 tokens to recharge the pool with
     * @param inputRewardAmounts An array of the amounts of each ERC20 token to
     * recharge the pool with
     * @param _newPeriodFinish The value to update this pool's `periodFinish` variable to
     */
    function rechargeRewardVault(
        IERC20[] calldata inputRewardTokens,
        uint256[] calldata inputRewardAmounts,
        uint256 _newPeriodFinish
    ) public virtual updateReward(address(0)) {
        if (msg.sender != deployer && msg.sender != protocolOwner) revert Unauthorized();
        if (_newPeriodFinish <= block.timestamp) revert BadEndTime();
        if (block.timestamp <= periodFinish) revert RewardsOngoing();
        uint256 oldRewardTokensLength = rewardTokens.length;
        uint256 newRewardTokensLength = inputRewardTokens.length;
        if (oldRewardTokensLength > newRewardTokensLength) revert MissingExistingTokens();
        if (newRewardTokensLength > MAX_REWARD_TOKENS) revert LengthLimitExceeded();
        if (newRewardTokensLength != inputRewardAmounts.length) revert LengthMismatch();

        // Mark each ERC20 in the input as used by this pool, and ensure no
        // duplicates within the input
        uint256 newReward;
        for (uint256 i; i < newRewardTokensLength;) {
            IERC20 inputRewardToken = inputRewardTokens[i];
            // ensure same ordering for existing tokens
            if (i < oldRewardTokensLength) {
                if (inputRewardToken != rewardTokens[i]) revert TokenMismatch();
            } else {
                // adding new token
                if (rewardTokenValid[inputRewardToken]) revert RepeatedToken();
                rewardTokenValid[inputRewardToken] = true;
            }

            // note that reward amounts can be zero
            newReward = inputRewardAmounts[i];
            // pull tokens
            if (newReward > 0) {
                inputRewardToken.safeTransferFrom(msg.sender, address(this), newReward);

                // newReward = new reward rate
                newReward /= (_newPeriodFinish - block.timestamp);
                if (newReward == 0) revert ZeroRewardRate();
            }
            rewardRates[inputRewardToken] = newReward;

            unchecked {
                ++i;
            }
        }

        rewardTokens = inputRewardTokens;
        lastUpdateTime = block.timestamp;
        periodFinish = _newPeriodFinish;
        rewardSweepTime = _newPeriodFinish + LOCK_TIME;

        emit RewardVaultRecharged(inputRewardTokens, inputRewardAmounts, block.timestamp, _newPeriodFinish);
    }

    /**
     * @notice Sends all ERC20 token balances of this pool to the deployer.
     */
    function sweepRewards() external {
        if (block.timestamp < rewardSweepTime) revert TooEarly();
        emit RewardSwept();
        uint256 rewardTokensLength = rewardTokens.length;
        address _deployer = deployer;
        unchecked {
            for (uint256 i; i < rewardTokensLength; ++i) {
                IERC20 rewardToken = rewardTokens[i];
                rewardToken.safeTransfer(_deployer, rewardToken.balanceOf(address(this)));
            }
        }
    }

    function atomicPoolAndVault(
        IERC721 _nft,
        ICurve _bondingCurve,
        uint128 _delta,
        uint96 _fee,
        uint128 _spotPrice,
        bytes calldata _props,
        bytes calldata _state,
        uint256 _royaltyNumerator,
        address payable _royaltyRecipientOverride,
        uint256[] calldata _initialNFTIDs
    ) external payable returns (uint256 currTokenId) {
        // create pool with empty NFTs first
        uint256[] memory _emptyInitialNFTIDs;
        address pool;

        (pool, currTokenId) = lpToken.createPoolETH{value: msg.value}(
            ICollectionPoolFactory.CreateETHPoolParams({
                nft: _nft,
                bondingCurve: _bondingCurve,
                assetRecipient: payable(0),
                receiver: msg.sender,
                poolType: ICollectionPool.PoolType.TRADE,
                delta: _delta,
                fee: _fee,
                spotPrice: _spotPrice,
                props: _props,
                state: _state,
                royaltyNumerator: _royaltyNumerator,
                royaltyRecipientOverride: _royaltyRecipientOverride,
                initialNFTIDs: _emptyInitialNFTIDs
            })
        );

        // transfer NFTs into pool
        for (uint256 i; i < _initialNFTIDs.length;) {
            _nft.safeTransferFrom(msg.sender, pool, _initialNFTIDs[i]);
            unchecked {
                ++i;
            }
        }

        stake(currTokenId);
    }

    function atomicExitAndUnpool(uint256 _tokenId) external {
        exit(_tokenId);
        lpToken.burn(_tokenId);
    }

    /**
     * @notice Add the balances of an LP token to the reward pool and mint
     * reward tokens
     * @param tokenId The tokenId of the LP token to be added to this reward
     * pool
     * @return amount The number of tokens minted
     */
    function mint(uint256 tokenId) private returns (uint256 amount) {
        ICollectionPoolFactory _lpToken = lpToken;
        if (_lpToken.ownerOf(tokenId) != msg.sender) revert Unauthorized();

        ICollectionPoolFactory.LPTokenParams721 memory params = _lpToken.viewPoolParams(tokenId);
        ICollectionPool _pool = ICollectionPool(params.poolAddress);
        IERC721 _nft = nft;
        if (
            params.nftAddress != address(_nft) || params.bondingCurveAddress != bondingCurve
                || !validator.validate(_pool, curveParams, fee, royaltyNumerator, tokenIDFilterRoot)
        ) revert PoolMismatch();

        // Calculate the number of tokens to mint. Equal to
        // sqrt(NFT balance * ETH balance) if there's enough ETH for the pool to
        // buy at least 1 NFT. Else 0.
        (uint128 _reserve0, uint128 _reserve1) = getReserves(); // gas savings
        uint256 amount0 = _nft.balanceOf(address(_pool));
        uint256 amount1 = address(_pool).balance;

        (,,,, uint256 bidPrice,,) = _pool.getSellNFTQuote(1);
        if (amount1 >= bidPrice) {
            amount = Math.sqrt(amount0 * amount1);
        }

        uint256 balance0 = _reserve0 + amount0;
        uint256 balance1 = _reserve1 + amount1;
        if (balance0 > type(uint128).max || balance1 > type(uint128).max) revert BalanceOverflow();

        reserve0 = uint128(balance0);
        reserve1 = uint128(balance1);
        lpTokenInfo[tokenId] = LPTokenInfo({amount0: amount0, amount1: amount1, amount: amount, owner: msg.sender});
    }

    /**
     * @notice Remove the balances of an LP token from the reward pool and burn
     * reward tokens
     * @param tokenId The tokenId of the LP token to be added to this reward
     * pool
     * @return amount The number of lp tokens burned
     */
    function burn(uint256 tokenId) internal virtual returns (uint256 amount) {
        LPTokenInfo memory lpTokenIdInfo = lpTokenInfo[tokenId];
        if (lpTokenIdInfo.owner != msg.sender) revert Unauthorized();
        amount = lpTokenIdInfo.amount;

        (uint128 _reserve0, uint128 _reserve1) = getReserves(); // gas savings

        reserve0 = uint128(_reserve0 - lpTokenIdInfo.amount0);
        reserve1 = uint128(_reserve1 - lpTokenIdInfo.amount1);

        delete lpTokenInfo[tokenId];
    }

    function onERC721Received(address, address, uint256, bytes memory) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @return The end of the period, or now if earlier
     */
    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    /**
     * @notice Calculate the amount of `_rewardToken` rewards accrued per reward
     * token.
     * @param _rewardToken The ERC20 token to be rewarded
     * @return The amount of `_rewardToken` awardable per reward token
     *
     */
    function rewardPerToken(IERC20 _rewardToken) public view returns (uint256) {
        uint256 lastRewardTime = lastTimeRewardApplicable();
        // latter condition required because calculations will revert when called externally
        // even though internally this function will only be called if lastRewardTime > lastUpdateTime
        if (totalSupply() == 0 || lastRewardTime <= lastUpdateTime) {
            return rewardPerTokenStored[_rewardToken];
        }
        return rewardPerTokenStored[_rewardToken]
            + (((lastRewardTime - lastUpdateTime) * rewardRates[_rewardToken] * 1e18) / totalSupply());
    }

    /**
     * @notice Calculate the amount of `_rewardToken` earned by `account`
     * @dev
     *
     * @param account The account to calculate earnings for
     * @param _rewardToken The ERC20 token to calculate earnings of
     * @return The amount of ERC20 token earned
     */
    function earned(address account, IERC20 _rewardToken) public view virtual returns (uint256) {
        return balanceOf(account) * (rewardPerToken(_rewardToken) - userRewardPerTokenPaid[_rewardToken][account])
            / (1e18) + rewards[_rewardToken][account];
    }

    /**
     * @notice Stake an LP token into the reward pool
     * @param tokenId The tokenId of the LP token to stake
     * @return amount The amount of reward token minted as a result
     */
    function stake(uint256 tokenId) public virtual updateReward(msg.sender) returns (uint256 amount) {
        if (tx.origin != msg.sender) revert CallerNotEOA();
        amount = mint(tokenId);
        if (amount == 0) revert NotTwoSidedLP();

        _totalSupply += amount;
        _balances[msg.sender] += amount;
        lpToken.safeTransferFrom(msg.sender, address(this), tokenId);
        emit Staked(msg.sender, tokenId, amount);
    }

    function withdraw(uint256 tokenId) public updateReward(msg.sender) {
        // amount will never be 0 because it is checked in stake()
        uint256 amount = burn(tokenId);
        _totalSupply -= amount;
        _balances[msg.sender] -= amount;
        lpToken.safeTransferFrom(address(this), msg.sender, tokenId);
        emit Withdrawn(msg.sender, tokenId, amount);
    }

    function exit(uint256 tokenId) public {
        withdraw(tokenId);
        getReward();
    }

    function getReward() public updateReward(msg.sender) {
        uint256 rewardTokensLength = rewardTokens.length;
        for (uint256 i; i < rewardTokensLength;) {
            IERC20 rewardToken = rewardTokens[i];
            uint256 reward = earned(msg.sender, rewardToken);
            if (reward > 0) {
                rewards[rewardToken][msg.sender] = 0;
                emit RewardPaid(rewardToken, msg.sender, reward);
                rewardToken.safeTransfer(msg.sender, reward);
            }
            unchecked {
                ++i;
            }
        }
    }

    function getReserves() public view returns (uint128 _reserve0, uint128 _reserve1) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {SortitionSumTreeFactory} from "../lib/SortitionSumTreeFactory.sol";

interface ISortitionTreeManager {
    function createTree(bytes32 _key, uint256 _K) external;

    function set(bytes32 _key, uint256 _value, bytes32 _ID) external;

    function queryLeafs(bytes32 _key, uint256 _cursor, uint256 _count)
        external
        view
        returns (uint256 startIndex, uint256[] memory values, bool hasMore);

    function draw(bytes32 _key, uint256 _drawnNumber) external view returns (bytes32 ID);

    function stakeOf(bytes32 _key, bytes32 _ID) external view returns (uint256 value);

    function total(bytes32 _key) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

/**
 * @title Random Number Generator Interface
 * @notice Provides an interface for requesting random numbers from 3rd-party RNG services (Chainlink VRF, Starkware VDF, etc..)
 */
interface RNGInterface {
    /**
     * @notice Emitted when a new request for a random number has been submitted
     * @param requestId The indexed ID of the request used to get the results of the RNG service
     * @param sender The indexed address of the sender of the request
     */
    event RandomNumberRequested(uint32 indexed requestId, address indexed sender);

    /**
     * @notice Emitted when an existing request for a random number has been completed
     * @param requestId The indexed ID of the request used to get the results of the RNG service
     * @param randomNumber The random number produced by the 3rd-party service
     */
    event RandomNumberCompleted(uint32 indexed requestId, uint256 randomNumber);

    /**
     * @notice Gets the last request id used by the RNG service
     * @return requestId The last request id used in the last request
     */
    function getLastRequestId() external view returns (uint32 requestId);

    /**
     * @notice Gets the Fee for making a Request against an RNG service
     * @return feeToken The address of the token that is used to pay fees
     * @return requestFee The fee required to be paid to make a request
     */
    function getRequestFee() external view returns (address feeToken, uint256 requestFee);

    /**
     * @notice Sends a request for a random number to the 3rd-party service
     * @dev Some services will complete the request immediately, others may have a time-delay
     * @dev Some services require payment in the form of a token, such as $LINK for Chainlink VRF
     * @return requestId The ID of the request used to get the results of the RNG service
     * @return lockBlock The block number at which the RNG service will start generating time-delayed randomness.
     * The calling contract should "lock" all activity until the result is available via the `requestId`
     */
    function requestRandomNumber() external returns (uint32 requestId, uint32 lockBlock);

    /**
     * @notice Checks if the request for randomness from the 3rd-party service has completed
     * @dev For time-delayed requests, this function is used to check/confirm completion
     * @param requestId The ID of the request used to get the results of the RNG service
     * @return isCompleted True if the request has completed and a random number is available, false otherwise
     */
    function isRequestComplete(uint32 requestId) external view returns (bool isCompleted);

    /**
     * @notice Gets the random number produced by the 3rd-party service
     * @param requestId The ID of the request used to get the results of the RNG service
     * @return randomNum The random number
     */
    function randomNumber(uint32 requestId) external returns (uint256 randomNum);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {ICurve} from "../bonding-curves/ICurve.sol";
import {ICollectionPool} from "../pools/ICollectionPool.sol";

interface IValidator {
    /// @notice Validates if a pool fulfills the conditions of a bonding curve. The conditions can be different for each type of curve.
    function validate(
        ICollectionPool pool,
        ICurve.Params calldata params,
        uint96 fee,
        uint256 royaltyNumerator,
        bytes32 tokenIDFilterRoot
    ) external returns (bool);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

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
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
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

/**
 *  @reviewers: [@clesaege, @unknownunknown1, @ferittuncer]
 *  @auditors: []
 *  @bounties: [<14 days 10 ETH max payout>]
 *  @deployments: []
 */

pragma solidity ^0.8.0;

/**
 *  @title SortitionSumTreeFactory
 *  @author Enrique Piqueras - <[email protected]>
 *  @dev A factory of trees that keep track of staked values for sortition.
 */
library SortitionSumTreeFactory {
    /* Structs */

    struct SortitionSumTree {
        uint K; // The maximum number of childs per node.
        // We use this to keep track of vacant positions in the tree after removing a leaf. This is for keeping the tree as balanced as possible without spending gas on moving nodes around.
        uint[] stack;
        uint[] nodes;
        // Two-way mapping of IDs to node indexes. Note that node index 0 is reserved for the root node, and means the ID does not have a node.
        mapping(bytes32 => uint) IDsToNodeIndexes;
        mapping(uint => bytes32) nodeIndexesToIDs;
    }

    /* Storage */

    struct SortitionSumTrees {
        mapping(bytes32 => SortitionSumTree) sortitionSumTrees;
    }

    /* internal */

    /**
     *  @dev Create a sortition sum tree at the specified key.
     *  @param _key The key of the new tree.
     *  @param _K The number of children each node in the tree should have.
     */
    function createTree(SortitionSumTrees storage self, bytes32 _key, uint _K) internal {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];
        require(tree.K == 0, "Tree already exists.");
        require(_K > 1, "K must be greater than one.");
        tree.K = _K;
        tree.stack = new uint[](0);
        tree.nodes = new uint[](0);
        tree.nodes.push(0);
    }

    /**
     *  @dev Set a value of a tree.
     *  @param _key The key of the tree.
     *  @param _value The new value.
     *  @param _ID The ID of the value.
     *  `O(log_k(n))` where
     *  `k` is the maximum number of childs per node in the tree,
     *   and `n` is the maximum number of nodes ever appended.
     */
    function set(SortitionSumTrees storage self, bytes32 _key, uint _value, bytes32 _ID) internal {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];
        uint treeIndex = tree.IDsToNodeIndexes[_ID];

        if (treeIndex == 0) { // No existing node.
            if (_value != 0) { // Non zero value.
                // Append.
                // Add node.
                if (tree.stack.length == 0) { // No vacant spots.
                    // Get the index and append the value.
                    treeIndex = tree.nodes.length;
                    tree.nodes.push(_value);

                    // Potentially append a new node and make the parent a sum node.
                    if (treeIndex != 1 && (treeIndex - 1) % tree.K == 0) { // Is first child.
                        uint parentIndex = treeIndex / tree.K;
                        bytes32 parentID = tree.nodeIndexesToIDs[parentIndex];
                        uint newIndex = treeIndex + 1;
                        tree.nodes.push(tree.nodes[parentIndex]);
                        delete tree.nodeIndexesToIDs[parentIndex];
                        tree.IDsToNodeIndexes[parentID] = newIndex;
                        tree.nodeIndexesToIDs[newIndex] = parentID;
                    }
                } else { // Some vacant spot.
                    // Pop the stack and append the value.
                    treeIndex = tree.stack[tree.stack.length - 1];
                    tree.stack.pop();
                    tree.nodes[treeIndex] = _value;
                }

                // Add label.
                tree.IDsToNodeIndexes[_ID] = treeIndex;
                tree.nodeIndexesToIDs[treeIndex] = _ID;

                updateParents(self, _key, treeIndex, true, _value);
            }
        } else { // Existing node.
            if (_value == 0) { // Zero value.
                // Remove.
                // Remember value and set to 0.
                uint value = tree.nodes[treeIndex];
                tree.nodes[treeIndex] = 0;

                // Push to stack.
                tree.stack.push(treeIndex);

                // Clear label.
                delete tree.IDsToNodeIndexes[_ID];
                delete tree.nodeIndexesToIDs[treeIndex];

                updateParents(self, _key, treeIndex, false, value);
            } else if (_value != tree.nodes[treeIndex]) { // New, non zero value.
                // Set.
                bool plusOrMinus = tree.nodes[treeIndex] <= _value;
                uint plusOrMinusValue = plusOrMinus ? _value - tree.nodes[treeIndex] : tree.nodes[treeIndex] - _value;
                tree.nodes[treeIndex] = _value;

                updateParents(self, _key, treeIndex, plusOrMinus, plusOrMinusValue);
            }
        }
    }

    /* internal Views */

    /**
     *  @dev Query the leaves of a tree. Note that if `startIndex == 0`, the tree is empty and the root node will be returned.
     *  @param _key The key of the tree to get the leaves from.
     *  @param _cursor The pagination cursor.
     *  @param _count The number of items to return.
     *  @return startIndex The index at which leaves start
     *  @return values The values of the returned leaves
     *  @return hasMore Whether there are more for pagination.
     *  `O(n)` where
     *  `n` is the maximum number of nodes ever appended.
     */
    function queryLeafs(
        SortitionSumTrees storage self,
        bytes32 _key,
        uint _cursor,
        uint _count
    ) internal view returns(uint startIndex, uint[] memory values, bool hasMore) {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];

        // Find the start index.
        for (uint i = 0; i < tree.nodes.length; i++) {
            if ((tree.K * i) + 1 >= tree.nodes.length) {
                startIndex = i;
                break;
            }
        }

        // Get the values.
        uint loopStartIndex = startIndex + _cursor;
        values = new uint[](loopStartIndex + _count > tree.nodes.length ? tree.nodes.length - loopStartIndex : _count);
        uint valuesIndex = 0;
        for (uint j = loopStartIndex; j < tree.nodes.length; j++) {
            if (valuesIndex < _count) {
                values[valuesIndex] = tree.nodes[j];
                valuesIndex++;
            } else {
                hasMore = true;
                break;
            }
        }
    }

    /**
     *  @dev Draw an ID from a tree using a number. Note that this function reverts if the sum of all values in the tree is 0.
     *  @param _key The key of the tree.
     *  @param _drawnNumber The drawn number.
     *  @return ID The drawn ID.
     *  `O(k * log_k(n))` where
     *  `k` is the maximum number of childs per node in the tree,
     *   and `n` is the maximum number of nodes ever appended.
     */
    function draw(SortitionSumTrees storage self, bytes32 _key, uint _drawnNumber) internal view returns(bytes32 ID) {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];
        uint treeIndex = 0;
        uint currentDrawnNumber = _drawnNumber % tree.nodes[0];

        while ((tree.K * treeIndex) + 1 < tree.nodes.length)  // While it still has children.
            for (uint i = 1; i <= tree.K; i++) { // Loop over children.
                uint nodeIndex = (tree.K * treeIndex) + i;
                uint nodeValue = tree.nodes[nodeIndex];

                if (currentDrawnNumber >= nodeValue) currentDrawnNumber -= nodeValue; // Go to the next child.
                else { // Pick this child.
                    treeIndex = nodeIndex;
                    break;
                }
            }
        
        ID = tree.nodeIndexesToIDs[treeIndex];
    }

    /** @dev Gets a specified ID's associated value.
     *  @param _key The key of the tree.
     *  @param _ID The ID of the value.
     *  @return value The associated value.
     */
    function stakeOf(SortitionSumTrees storage self, bytes32 _key, bytes32 _ID) internal view returns(uint value) {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];
        uint treeIndex = tree.IDsToNodeIndexes[_ID];

        if (treeIndex == 0) value = 0;
        else value = tree.nodes[treeIndex];
    }

    function total(SortitionSumTrees storage self, bytes32 _key) internal view returns (uint) {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];
        if (tree.nodes.length == 0) {
            return 0;
        } else {
            return tree.nodes[0];
        }
    }

    /* Private */

    /**
     *  @dev Update all the parents of a node.
     *  @param _key The key of the tree to update.
     *  @param _treeIndex The index of the node to start from.
     *  @param _plusOrMinus Wether to add (true) or substract (false).
     *  @param _value The value to add or substract.
     *  `O(log_k(n))` where
     *  `k` is the maximum number of childs per node in the tree,
     *   and `n` is the maximum number of nodes ever appended.
     */
    function updateParents(SortitionSumTrees storage self, bytes32 _key, uint _treeIndex, bool _plusOrMinus, uint _value) private {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];

        uint parentIndex = _treeIndex;
        while (parentIndex != 0) {
            parentIndex = (parentIndex - 1) / tree.K;
            tree.nodes[parentIndex] = _plusOrMinus ? tree.nodes[parentIndex] + _value : tree.nodes[parentIndex] - _value;
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ICollectionPoolFactory} from "../pools/ICollectionPoolFactory.sol";
import {RewardVaultETH} from "./RewardVaultETH.sol";
import {RewardVaultETHDraw} from "./RewardVaultETHDraw.sol";
import {ICurve} from "../bonding-curves/ICurve.sol";
import {IValidator} from "../validators/IValidator.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {RNGChainlinkV2Interface} from "../rng/RNGChainlinkV2Interface.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {ISortitionTreeManager} from "../tree/ISortitionTreeManager.sol";
import {SortitionTreeManager} from "../tree/SortitionTreeManager.sol";

contract Collectionstaker is Ownable {
    using SafeERC20 for IERC20;

    ICollectionPoolFactory public immutable lpToken;
    ISortitionTreeManager public immutable treeManager;
    RewardVaultETH public immutable rewardVaultETHLogic;
    RewardVaultETHDraw public immutable rewardVaultETHDrawLogic;
    uint256 public constant MAX_REWARD_TOKENS = 5;
    RNGChainlinkV2Interface public rngChainlink;

    /// @notice Event emitted when a liquidity mining incentive has been created
    /// @param poolAddress The Reward pool address
    /// @param rewardTokens The tokens being distributed as a reward
    /// @param rewards The amount of reward tokens to be distributed
    /// @param startTime The time when the incentive program begins
    /// @param endTime The time when rewards stop accruing
    event IncentiveETHCreated(
        address poolAddress, IERC20[] rewardTokens, uint256[] rewards, uint256 startTime, uint256 endTime
    );

    event IncentiveETHDrawCreated(
        address poolAddress, IERC20[] rewardTokens, uint256[] rewards, uint256 startTime, uint256 endTime
    );

    constructor(ICollectionPoolFactory _lpToken) {
        lpToken = _lpToken;
        treeManager = new SortitionTreeManager();
        rewardVaultETHLogic = new RewardVaultETH();
        rewardVaultETHDrawLogic = new RewardVaultETHDraw();
    }

    function setRNG(RNGChainlinkV2Interface _rngChainlink) external onlyOwner {
        rngChainlink = _rngChainlink;
    }

    /**
     * @notice The createIncentiveETH function is used to create a new liquidity mining incentive program for a specific trading pool. The function takes the following parameters:
     * @param validator: The address of the validator contract that will be used to verify the authenticity of the trading pool.
     * @param nft: The address of the non-fungible token that is being traded in the trading pool.
     * @param bondingCurve: The address of the bonding curve contract that is being used by the trading pool.
     * @param curveParams: The curve parameters that are being used by the bonding curve contract.
     * @param fee: The fee that will be charged on trades made using the trading pool.
     * @param rewardTokens: An array of token addresses that will be used as rewards in the incentive program.
     * @param rewards: An array of reward amounts that will be distributed to liquidity providers. This is the whole amount, which will be divided by the duration of the incentive program as an argument to the child initialize() function
     * @param startTime: The time when the incentive program begins.
     * @param endTime: The time at which the incentive program will end and rewards will no longer be distributed.
     */
    function createIncentiveETH(
        IValidator validator,
        IERC721 nft,
        address bondingCurve,
        ICurve.Params calldata curveParams,
        uint96 fee,
        uint256 royaltyNumerator,
        bytes32 tokenIDFilterRoot,
        IERC20[] calldata rewardTokens,
        uint256[] calldata rewards,
        uint256 startTime,
        uint256 endTime
    ) external {
        require(startTime > block.timestamp, "cannot backdate");
        uint256 rewardTokensLength = rewardTokens.length;
        require(rewardTokensLength <= MAX_REWARD_TOKENS, "too many reward tokens");
        require(rewardTokensLength == rewards.length, "unequal lengths");
        uint256[] memory rewardRates = new uint256[](rewardTokensLength);
        for (uint256 i; i < rewardTokensLength;) {
            rewardRates[i] = rewards[i] / (endTime - startTime); // guaranteed endTime > startTime
            require(rewardRates[i] != 0, "0 rate");
            unchecked {
                ++i;
            }
        }
        RewardVaultETH rewardVault = RewardVaultETH(Clones.clone(address(rewardVaultETHLogic)));

        rewardVault.initialize(
            owner(),
            msg.sender,
            lpToken,
            validator,
            nft,
            bondingCurve,
            curveParams,
            fee,
            royaltyNumerator,
            tokenIDFilterRoot,
            rewardTokens,
            rewardRates,
            startTime,
            endTime
        );

        // transfer reward tokens to RewardVault
        for (uint256 i; i < rewardTokensLength;) {
            rewardTokens[i].safeTransferFrom(msg.sender, address(rewardVault), rewards[i]);

            unchecked {
                ++i;
            }
        }

        emit IncentiveETHCreated(address(rewardVault), rewardTokens, rewards, startTime, endTime);
    }

    /**
     * @notice The randomnessIsSet function is a contract modifier that checks whether the rngChainlink contract has been set. If it has not been set, this modifier will throw an exception and prevent the contract's function from executing. This ensures that the contract's functions that rely on randomness generated by the rngChainlink contract will only be executed if the rngChainlink contract has been properly initialized.
     * @dev permission for liquidity vaults to call the Chainlink v2 RNG comes this contract
     */
    modifier randomnessIsSet() {
        require(address(rngChainlink) != address(0), "randomness not set");
        _;
    }

    /**
     * @notice The createIncentiveETHDraw function is used to create a new liquidity mining incentive program for a specific trading pool. The function takes the following parameters:
     * @param validator: The address of the validator contract that will be used to verify the authenticity of the trading pool.
     * @param nft: The address of the non-fungible token that is being traded in the trading pool.
     * @param bondingCurve: The address of the bonding curve contract that is being used by the trading pool.
     * @param curveParams: The curve parameters that are being used by the bonding curve contract.
     * @param fee: The fee that will be charged on trades made using the trading pool.
     * @param rewardTokens: An array of token addresses that will be used as rewards in the incentive program.
     * @param rewards: An array of reward amounts that will be distributed to liquidity providers. This is the whole amount, which will be divided by the duration of the incentive program as an argument to the child initialize() function
     * @param rewardStartTime: The time when the incentive program begins.
     * @param rewardEndTime: The time at which the incentive program will end and rewards will no longer be distributed.
     * @param _additionalERC20DrawPrize: The array of ERC20 tokens that will be distributed as additional prizes in the draw.
     * @param _additionalERC20DrawAmounts: The array of ERC20 token amounts that will be distributed as additional prizes in the draw.
     * @param _nftCollectionsPrize The NFT collections that will be awarded as prizes.
     * @param _nftIdsPrize The IDs of the NFTs that will be awarded as prizes.
     * @param _prizesPerWinner The number of prizes that will be awarded to each winner.
     * @param drawStartTime The time when the prize draw will begin. Not necessarily the same as the rewards programme
     * @param drawPeriodFinish The time when the prize draw will end. Not necessarily the same as the rewards programme
     */
    function createIncentiveETHDraw(
        IValidator validator,
        IERC721 nft,
        address bondingCurve,
        ICurve.Params calldata curveParams,
        uint96 fee,
        uint256 royaltyNumerator,
        bytes32 tokenIDFilterRoot,
        IERC20[] calldata rewardTokens,
        uint256[] calldata rewards,
        uint256 rewardStartTime,
        uint256 rewardEndTime,
        IERC20[] calldata _additionalERC20DrawPrize,
        uint256[] calldata _additionalERC20DrawAmounts,
        IERC721[] calldata _nftCollectionsPrize,
        uint256[] calldata _nftIdsPrize,
        uint256 _prizesPerWinner,
        uint256 drawStartTime,
        uint256 drawPeriodFinish
    ) public randomnessIsSet {
        uint256 rewardTokensLength = rewardTokens.length;
        if (rewardStartTime != 0) {
            // deployer intends to use normal reward distribution functionality
            // same checks apply as per createIncentiveETH()
            require(rewardStartTime > block.timestamp, "cannot backdate");
            require(rewardTokensLength <= MAX_REWARD_TOKENS, "too many reward tokens");
            require(rewardTokensLength == rewards.length, "unequal lengths");
        } else {
            // rewardStartTime == 0 => deployer intends to initially utilise draw functionality only
            require(rewardTokensLength == 0, "bad config");
        }

        uint256[] memory rewardRates = new uint256[](rewardTokensLength);
        for (uint256 i; i < rewardTokensLength;) {
            rewardRates[i] = rewards[i] / (rewardEndTime - rewardStartTime); // guaranteed endTime > startTime
            require(rewardRates[i] != 0, "0 rate");
            unchecked {
                ++i;
            }
        }

        RewardVaultETHDraw rewardVault = RewardVaultETHDraw(Clones.clone(address(rewardVaultETHDrawLogic)));

        rewardVault.initialize(
            owner(),
            msg.sender,
            lpToken,
            validator,
            nft,
            bondingCurve,
            curveParams,
            fee,
            royaltyNumerator,
            tokenIDFilterRoot,
            rewardTokens,
            rewardRates,
            rewardStartTime,
            rewardEndTime,
            rngChainlink,
            _additionalERC20DrawPrize,
            _additionalERC20DrawAmounts,
            _nftCollectionsPrize,
            _nftIdsPrize,
            _prizesPerWinner,
            drawStartTime,
            drawPeriodFinish,
            treeManager
        );

        rngChainlink.setAllowedCaller(address(rewardVault));

        // transfer erc20 drawTokens to RewardVault
        for (uint256 i; i < _additionalERC20DrawPrize.length;) {
            _additionalERC20DrawPrize[i].safeTransferFrom(
                msg.sender, address(rewardVault), _additionalERC20DrawAmounts[i]
            );

            unchecked {
                ++i;
            }
        }

        // transfer erc721 drawTokens to RewardVault
        for (uint256 i; i < _nftCollectionsPrize.length;) {
            _nftCollectionsPrize[i].safeTransferFrom(msg.sender, address(rewardVault), _nftIdsPrize[i]);

            unchecked {
                ++i;
            }
        }

        // transfer reward tokens to RewardVault
        for (uint256 i; i < rewardTokensLength;) {
            rewardTokens[i].safeTransferFrom(msg.sender, address(rewardVault), rewards[i]);

            unchecked {
                ++i;
            }
        }

        emit IncentiveETHDrawCreated(address(rewardVault), rewardTokens, rewards, rewardStartTime, rewardEndTime);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

import "./RNGInterface.sol";

/**
 * @title RNG Chainlink V2 Interface
 * @notice Provides an interface for requesting random numbers from Chainlink VRF V2.
 */
interface RNGChainlinkV2Interface is RNGInterface {
    /**
     * @notice Get Chainlink VRF keyHash associated with this contract.
     * @return bytes32 Chainlink VRF keyHash
     */
    function getKeyHash() external view returns (bytes32);

    /**
     * @notice Get Chainlink VRF subscription id associated with this contract.
     * @return uint64 Chainlink VRF subscription id
     */
    function getSubscriptionId() external view returns (uint64);

    /**
     * @notice Get Chainlink VRF coordinator contract address associated with this contract.
     * @return address Chainlink VRF coordinator address
     */
    function getVrfCoordinator() external view returns (VRFCoordinatorV2Interface);

    /**
     * @notice Set Chainlink VRF keyHash.
     * @dev This function is only callable by the owner.
     * @param keyHash Chainlink VRF keyHash
     */
    function setKeyhash(bytes32 keyHash) external;

    /**
     * @notice Set Chainlink VRF subscription id associated with this contract.
     * @dev This function is only callable by the owner.
     * @param subscriptionId Chainlink VRF subscription id
     */
    function setSubscriptionId(uint64 subscriptionId) external;

    /// for a factory contract to set the child contracts as allowed callers
    function setAllowedCaller(address allowed) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {SortitionSumTreeFactory} from "../lib/SortitionSumTreeFactory.sol";
import {ISortitionTreeManager} from "./ISortitionTreeManager.sol";

contract SortitionTreeManager is ISortitionTreeManager {
    using SortitionSumTreeFactory for SortitionSumTreeFactory.SortitionSumTrees;

    mapping(address => SortitionSumTreeFactory.SortitionSumTrees) private userTrees;

    function createTree(bytes32 _key, uint256 _K) public {
        SortitionSumTreeFactory.SortitionSumTrees storage trees = userTrees[msg.sender];
        trees.createTree(_key, _K);
    }

    function set(bytes32 _key, uint256 _value, bytes32 _ID) public {
        SortitionSumTreeFactory.SortitionSumTrees storage trees = userTrees[msg.sender];
        trees.set(_key, _value, _ID);
    }

    function queryLeafs(bytes32 _key, uint256 _cursor, uint256 _count)
        public
        view
        returns (uint256 startIndex, uint256[] memory values, bool hasMore)
    {
        SortitionSumTreeFactory.SortitionSumTrees storage trees = userTrees[msg.sender];
        return trees.queryLeafs(_key, _cursor, _count);
    }

    function draw(bytes32 _key, uint256 _drawnNumber) public view returns (bytes32 ID) {
        SortitionSumTreeFactory.SortitionSumTrees storage trees = userTrees[msg.sender];
        return trees.draw(_key, _drawnNumber);
    }

    function stakeOf(bytes32 _key, bytes32 _ID) public view returns (uint256 value) {
        SortitionSumTreeFactory.SortitionSumTrees storage trees = userTrees[msg.sender];
        return trees.stakeOf(_key, _ID);
    }

    function total(bytes32 _key) public view returns (uint256) {
        SortitionSumTreeFactory.SortitionSumTrees storage trees = userTrees[msg.sender];
        return trees.total(_key);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

// import {RNGServiceMock} from "./RNGServiceMock.sol";
import {RNGChainlinkV2Interface} from "./RNGChainlinkV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

contract RNGServiceMockChainlink is RNGChainlinkV2Interface {
    uint256 internal random;
    address internal feeToken;
    uint256 internal requestFee;
    uint32 internal _lastRequestId = 0;

    function getLastRequestId() external view override returns (uint32 requestId) {
        return _lastRequestId;
    }

    function setRequestFee(address _feeToken, uint256 _requestFee) external {
        feeToken = _feeToken;
        requestFee = _requestFee;
    }

    /// @return _feeToken
    /// @return _requestFee
    function getRequestFee() external view override returns (address _feeToken, uint256 _requestFee) {
        return (feeToken, requestFee);
    }

    function setRandomNumber(uint256 _random) external {
        random = _random;
    }

    function requestRandomNumber() external override returns (uint32, uint32) {
        ++_lastRequestId;
        return (_lastRequestId, 1);
    }

    function isRequestComplete(uint32) external pure override returns (bool) {
        return true;
    }

    function randomNumber(uint32) external view override returns (uint256) {
        return random;
    }

    function getKeyHash() external view override returns (bytes32) {
        return bytes32(0);
    }

    function getSubscriptionId() external view override returns (uint64) {
        return 0;
    }

    function getVrfCoordinator() external view override returns (VRFCoordinatorV2Interface) {
        return VRFCoordinatorV2Interface(address(0));
    }

    function setKeyhash(bytes32 keyHash) external override {}

    function setSubscriptionId(uint64 subscriptionId) external override {}

    function setAllowedCaller(address allowed) external override {}
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "../lib/Manageable.sol";
import "./RNGChainlinkV2Interface.sol";

contract RNGChainlinkV2 is RNGChainlinkV2Interface, VRFConsumerBaseV2, Manageable {
    /* ============ Global Variables ============ */

    /// @dev Reference to the VRFCoordinatorV2 deployed contract
    VRFCoordinatorV2Interface internal vrfCoordinator;

    /// @dev A counter for the number of requests made used for request ids
    uint32 internal requestCounter;

    /// @dev Chainlink VRF subscription id
    uint64 internal subscriptionId;

    /// @dev Hash of the public key used to verify the VRF proof
    bytes32 internal keyHash;

    /// @dev A list of random numbers from past requests mapped by request id
    mapping(uint32 => uint256) internal randomNumbers;

    /// @dev A list of blocks to be locked at based on past requests mapped by request id
    mapping(uint32 => uint32) internal requestLockBlock;

    /// @dev A mapping from Chainlink request ids to internal request ids
    mapping(uint256 => uint32) internal chainlinkRequestIds;

    /// mapping of allowances
    mapping(address => bool) internal allowedToCallRandomness;

    /* ============ Events ============ */

    /**
     * @notice Emitted when the Chainlink VRF keyHash is set
     * @param keyHash Chainlink VRF keyHash
     */
    event KeyHashSet(bytes32 keyHash);

    /**
     * @notice Emitted when the Chainlink VRF subscription id is set
     * @param subscriptionId Chainlink VRF subscription id
     */
    event SubscriptionIdSet(uint64 subscriptionId);

    /**
     * @notice Emitted when the Chainlink VRF Coordinator address is set
     * @param vrfCoordinator Address of the VRF Coordinator
     */
    event VrfCoordinatorSet(VRFCoordinatorV2Interface indexed vrfCoordinator);

    /* ============ Constructor ============ */

    /**
     * @notice Constructor of the contract
     * @param _owner Owner of the contract
     * @param _vrfCoordinator Address of the VRF Coordinator
     * @param _subscriptionId Chainlink VRF subscription id
     * @param _keyHash Hash of the public key used to verify the VRF proof
     */
    constructor(address _owner, VRFCoordinatorV2Interface _vrfCoordinator, uint64 _subscriptionId, bytes32 _keyHash)
        Ownable(_owner)
        VRFConsumerBaseV2(address(_vrfCoordinator))
    {
        _setVRFCoordinator(_vrfCoordinator);
        _setSubscriptionId(_subscriptionId);
        _setKeyhash(_keyHash);
        allowedToCallRandomness[_owner] = true;
        allowedToCallRandomness[msg.sender] = true;
    }

    /* ============ External Functions ============ */

    /// @inheritdoc RNGInterface
    function requestRandomNumber() external override onlyAllowedCaller returns (uint32 requestId, uint32 lockBlock) {
        uint256 _vrfRequestId = vrfCoordinator.requestRandomWords(keyHash, subscriptionId, 3, 1000000, 1);

        requestCounter++;
        uint32 _requestCounter = requestCounter;

        requestId = _requestCounter;
        chainlinkRequestIds[_vrfRequestId] = _requestCounter;

        lockBlock = uint32(block.number);
        requestLockBlock[_requestCounter] = lockBlock;

        emit RandomNumberRequested(_requestCounter, msg.sender);
    }

    /// @inheritdoc RNGInterface
    function isRequestComplete(uint32 _internalRequestId) external view override returns (bool isCompleted) {
        return randomNumbers[_internalRequestId] != 0;
    }

    /// @inheritdoc RNGInterface
    function randomNumber(uint32 _internalRequestId) external view override returns (uint256 randomNum) {
        return randomNumbers[_internalRequestId];
    }

    /// @inheritdoc RNGInterface
    function getLastRequestId() external view override returns (uint32 requestId) {
        return requestCounter;
    }

    /// @inheritdoc RNGInterface
    function getRequestFee() external pure override returns (address feeToken, uint256 requestFee) {
        return (address(0), 0);
    }

    /// @inheritdoc RNGChainlinkV2Interface
    function getKeyHash() external view override returns (bytes32) {
        return keyHash;
    }

    /// @inheritdoc RNGChainlinkV2Interface
    function getSubscriptionId() external view override returns (uint64) {
        return subscriptionId;
    }

    /// @inheritdoc RNGChainlinkV2Interface
    function getVrfCoordinator() external view override returns (VRFCoordinatorV2Interface) {
        return vrfCoordinator;
    }

    /// @inheritdoc RNGChainlinkV2Interface
    function setSubscriptionId(uint64 _subscriptionId) external override onlyOwner {
        _setSubscriptionId(_subscriptionId);
    }

    /// @inheritdoc RNGChainlinkV2Interface
    function setKeyhash(bytes32 _keyHash) external override onlyOwner {
        _setKeyhash(_keyHash);
    }

    /// for a factory contract to set the child contracts as allowed callers
    function setAllowedCaller(address allowed) external override onlyAllowedCaller {
        allowedToCallRandomness[allowed] = true;
    }

    /* ============ Internal Functions ============ */

    /**
     * @notice Callback function called by VRF Coordinator
     * @dev The VRF Coordinator will only call it once it has verified the proof associated with the randomness.
     * @param _vrfRequestId Chainlink VRF request id
     * @param _randomWords Chainlink VRF array of random words
     */
    function fulfillRandomWords(uint256 _vrfRequestId, uint256[] memory _randomWords) internal override {
        uint32 _internalRequestId = chainlinkRequestIds[_vrfRequestId];
        require(_internalRequestId > 0, "RNGChainLink/requestId-incorrect");

        uint256 _randomNumber = _randomWords[0];
        // range is from 1 to type(uint256).max
        randomNumbers[_internalRequestId] = (_randomNumber % type(uint256).max) + 1;

        emit RandomNumberCompleted(_internalRequestId, _randomNumber);
    }

    /**
     * @notice Set Chainlink VRF coordinator contract address.
     * @param _vrfCoordinator Chainlink VRF coordinator contract address
     */
    function _setVRFCoordinator(VRFCoordinatorV2Interface _vrfCoordinator) internal {
        require(address(_vrfCoordinator) != address(0), "RNGChainLink/vrf-not-zero-addr");
        vrfCoordinator = _vrfCoordinator;
        emit VrfCoordinatorSet(_vrfCoordinator);
    }

    /**
     * @notice Set Chainlink VRF subscription id associated with this contract.
     * @param _subscriptionId Chainlink VRF subscription id
     */
    function _setSubscriptionId(uint64 _subscriptionId) internal {
        require(_subscriptionId > 0, "RNGChainLink/subId-gt-zero");
        subscriptionId = _subscriptionId;
        emit SubscriptionIdSet(_subscriptionId);
    }

    /**
     * @notice Set Chainlink VRF keyHash.
     * @param _keyHash Chainlink VRF keyHash
     */
    function _setKeyhash(bytes32 _keyHash) internal {
        require(_keyHash != bytes32(0), "RNGChainLink/keyHash-not-empty");
        keyHash = _keyHash;
        emit KeyHashSet(_keyHash);
    }

    modifier onlyAllowedCaller() {
        require(allowedToCallRandomness[msg.sender], "RNGChainLink/caller-not-allowed");
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

/**
 * @title Abstract ownable contract that can be inherited by other contracts
 * @notice Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner is the deployer of the contract.
 *
 * The owner account is set through a two steps process.
 *      1. The current `owner` calls {transferOwnership} to set a `pendingOwner`
 *      2. The `pendingOwner` calls {acceptOwnership} to accept the ownership transfer
 *
 * The manager account needs to be set using {setManager}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable {
    address private _owner;
    address private _pendingOwner;

    /**
     * @dev Emitted when `_pendingOwner` has been changed.
     * @param pendingOwner new `_pendingOwner` address.
     */
    event OwnershipOffered(address indexed pendingOwner);

    /**
     * @dev Emitted when `_owner` has been changed.
     * @param previousOwner previous `_owner` address.
     * @param newOwner new `_owner` address.
     */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /* ============ Deploy ============ */

    /**
     * @notice Initializes the contract setting `_initialOwner` as the initial owner.
     * @param _initialOwner Initial owner of the contract.
     */
    constructor(address _initialOwner) {
        _setOwner(_initialOwner);
    }

    /* ============ External Functions ============ */

    /**
     * @notice Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @notice Gets current `_pendingOwner`.
     * @return Current `_pendingOwner` address.
     */
    function pendingOwner() external view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @notice Renounce ownership of the contract.
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() external virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
    * @notice Allows current owner to set the `_pendingOwner` address.
    * @param _newOwner Address to transfer ownership to.
    */
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Ownable/pendingOwner-not-zero-address");

        _pendingOwner = _newOwner;

        emit OwnershipOffered(_newOwner);
    }

    /**
    * @notice Allows the `_pendingOwner` address to finalize the transfer.
    * @dev This function is only callable by the `_pendingOwner`.
    */
    function claimOwnership() external onlyPendingOwner {
        _setOwner(_pendingOwner);
        _pendingOwner = address(0);
    }

    /* ============ Internal Functions ============ */

    /**
     * @notice Internal function to set the `_owner` of the contract.
     * @param _newOwner New `_owner` address.
     */
    function _setOwner(address _newOwner) private {
        address _oldOwner = _owner;
        _owner = _newOwner;
        emit OwnershipTransferred(_oldOwner, _newOwner);
    }

    /* ============ Modifier Functions ============ */

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable/caller-not-owner");
        _;
    }

    /**
    * @dev Throws if called by any account other than the `pendingOwner`.
    */
    modifier onlyPendingOwner() {
        require(msg.sender == _pendingOwner, "Ownable/caller-not-pendingOwner");
        _;
    }
}

/**
 * @title Abstract manageable contract that can be inherited by other contracts
 * @notice Contract module based on Ownable which provides a basic access control mechanism, where
 * there is an owner and a manager that can be granted exclusive access to specific functions.
 *
 * By default, the owner is the deployer of the contract.
 *
 * The owner account is set through a two steps process.
 *      1. The current `owner` calls {transferOwnership} to set a `pendingOwner`
 *      2. The `pendingOwner` calls {acceptOwnership} to accept the ownership transfer
 *
 * The manager account needs to be set using {setManager}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyManager`, which can be applied to your functions to restrict their use to
 * the manager.
 */
abstract contract Manageable is Ownable {
    address private _manager;

    /**
     * @dev Emitted when `_manager` has been changed.
     * @param previousManager previous `_manager` address.
     * @param newManager new `_manager` address.
     */
    event ManagerTransferred(address indexed previousManager, address indexed newManager);

    /* ============ External Functions ============ */

    /**
     * @notice Gets current `_manager`.
     * @return Current `_manager` address.
     */
    function manager() public view virtual returns (address) {
        return _manager;
    }

    /**
     * @notice Set or change of manager.
     * @dev Throws if called by any account other than the owner.
     * @param _newManager New _manager address.
     * @return Boolean to indicate if the operation was successful or not.
     */
    function setManager(address _newManager) external onlyOwner returns (bool) {
        return _setManager(_newManager);
    }

    /* ============ Internal Functions ============ */

    /**
     * @notice Set or change of manager.
     * @param _newManager New _manager address.
     * @return Boolean to indicate if the operation was successful or not.
     */
    function _setManager(address _newManager) private returns (bool) {
        address _previousManager = _manager;

        require(_newManager != _previousManager, "Manageable/existing-manager-address");

        _manager = _newManager;

        emit ManagerTransferred(_previousManager, _newManager);
        return true;
    }

    /* ============ Modifier Functions ============ */

    /**
     * @dev Throws if called by any account other than the manager.
     */
    modifier onlyManager() {
        require(manager() == msg.sender, "Manageable/caller-not-manager");
        _;
    }

    /**
     * @dev Throws if called by any account other than the manager or the owner.
     */
    modifier onlyManagerOrOwner() {
        require(manager() == msg.sender || owner() == msg.sender, "Manageable/caller-not-manager-or-owner");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import "./RNGInterface.sol";

contract RNGServiceMock is RNGInterface {
    uint256 internal random;
    address internal feeToken;
    uint256 internal requestFee;
    uint32 internal _lastRequestId = 0;

    function getLastRequestId() external view override returns (uint32 requestId) {
        return _lastRequestId;
    }

    function setRequestFee(address _feeToken, uint256 _requestFee) external {
        feeToken = _feeToken;
        requestFee = _requestFee;
    }

    /// @return _feeToken
    /// @return _requestFee
    function getRequestFee() external view override returns (address _feeToken, uint256 _requestFee) {
        return (feeToken, requestFee);
    }

    function setRandomNumber(uint256 _random) external {
        random = _random;
    }

    function requestRandomNumber() external override returns (uint32, uint32) {
        ++_lastRequestId;
        return (_lastRequestId, 1);
    }

    function isRequestComplete(uint32) external pure override returns (bool) {
        return true;
    }

    function randomNumber(uint32) external view override returns (uint256) {
        return random;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IValidator} from "./IValidator.sol";
import {ICurve} from "../bonding-curves/ICurve.sol";
import {ICollectionPool} from "../pools/ICollectionPool.sol";

/// @notice MonotonicIncreasingValidator is suitable for all bonding curves that are monotonic increasing.
/// i.e. the spot price is always non-decreasing when delta increases.
/// While most parameters are validated with an at most relation to keeping the spread tight,
/// the royalty numerator is validated with an at least as the nft collection would be keener to receive more royalties than keeping spread tight absolutely.
/// @dev Only suitable for TRADE pools
contract MonotonicIncreasingValidator is IValidator {
    /// @dev See {IValidator-validate}
    function validate(
        ICollectionPool pool,
        ICurve.Params calldata params,
        uint96 fee,
        uint256 royaltyNumerator,
        bytes32 tokenIDFilterRoot
    ) public view override returns (bool) {
        return (
            pool.delta() <= params.delta && pool.fee() <= fee && pool.royaltyNumerator() >= royaltyNumerator
                && pool.poolType() == ICollectionPool.PoolType.TRADE && pool.tokenIDFilterRoot() == tokenIDFilterRoot
        );
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.4;

import {ERC165Checker} from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import {IOwnershipTransferCallback} from "./IOwnershipTransferCallback.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

abstract contract OwnableWithTransferCallback {
    using ERC165Checker for address;
    using Address for address;

    bytes4 constant TRANSFER_CALLBACK =
        type(IOwnershipTransferCallback).interfaceId;

    error Ownable_NotOwner();
    error Ownable_NewOwnerZeroAddress();

    address private _owner;

    event OwnershipTransferred(address indexed newOwner);

    /// @dev Initializes the contract setting the deployer as the initial owner.
    function __Ownable_init(address initialOwner) internal {
        _owner = initialOwner;
    }

    /// @dev Returns the address of the current owner.
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /// @dev Throws if called by any account other than the owner.
    modifier onlyOwner() {
        if (owner() != msg.sender) revert Ownable_NotOwner();
        _;
    }

    /// @dev Transfers ownership of the contract to a new account (`newOwner`).
    /// Disallows setting to the zero address as a way to more gas-efficiently avoid reinitialization
    /// When ownership is transferred, if the new owner implements IOwnershipTransferCallback, we make a callback
    /// Can only be called by the current owner.
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) revert Ownable_NewOwnerZeroAddress();
        _transferOwnership(newOwner);

        // Call the on ownership transfer callback if it exists
        // @dev try/catch is around 5k gas cheaper than doing ERC165 checking
        if (newOwner.isContract()) {
            try
                IOwnershipTransferCallback(newOwner).onOwnershipTransfer(msg.sender)
            {} catch (bytes memory) {}
        }
    }

    /// @dev Transfers ownership of the contract to a new account (`newOwner`).
    /// Internal function without access restriction.
    function _transferOwnership(address newOwner) internal virtual {
        _owner = newOwner;
        emit OwnershipTransferred(newOwner);
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.4;

interface IOwnershipTransferCallback {
  function onOwnershipTransfer(address oldOwner) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {ICurve} from "./ICurve.sol";
import {CurveErrorCodes} from "./CurveErrorCodes.sol";
import {CollectionPool} from "../pools/CollectionPool.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {CollectionPoolCloner} from "../lib/CollectionPoolCloner.sol";
import {CollectionPoolERC20} from "../pools/CollectionPoolERC20.sol";
import {FixedPointMathLib} from "../lib/FixedPointMathLib.sol";

/*
    @author Collection
    @notice Bonding curve logic for an x*y=k curve using virtual reserves.
    @dev    The virtual token reserve is stored in `spotPrice` and the virtual nft reserve is stored in `delta`.
            An LP can modify the virtual reserves by changing the `spotPrice` (tokens) or `delta` (nfts).*/
contract XykCurve is ICurve, CurveErrorCodes {
    using FixedPointMathLib for uint256;

    /**
     * @dev See {ICurve-validateDelta}
     */
    function validateDelta(uint128) external pure override returns (bool) {
        // all values are valid
        return true;
    }

    /**
     * @dev See {ICurve-validateSpotPrice}
     */
    function validateSpotPrice(uint128) external pure override returns (bool) {
        // all values are valid
        return true;
    }

    /**
     * @dev See {ICurve-validateProps}
     */
    function validateProps(bytes calldata /*props*/ ) external pure override returns (bool valid) {
        // all values are valid
        return true;
    }

    /**
     * @dev See {ICurve-validateState}
     */
    function validateState(bytes calldata /*state*/ ) external pure override returns (bool valid) {
        // all values are valid
        return true;
    }

    /**
     * @dev See {ICurve-getBuyInfo}
     */
    function getBuyInfo(ICurve.Params calldata params, uint256 numItems, ICurve.FeeMultipliers calldata feeMultipliers)
        external
        pure
        override
        returns (Error error, ICurve.Params memory newParams, uint256 inputValue, ICurve.Fees memory fees)
    {
        if (numItems == 0) {
            return (Error.INVALID_NUMITEMS, ICurve.Params(0, 0, "", ""), 0, ICurve.Fees(0, 0, new uint256[](0)));
        }

        // get the pool's virtual nft and eth/erc20 reserves
        uint256 tokenBalance = params.spotPrice;
        uint256 nftBalance = params.delta;

        // If numItems is too large, we will get divide by zero error
        if (numItems >= nftBalance) {
            return (Error.INVALID_NUMITEMS, ICurve.Params(0, 0, "", ""), 0, ICurve.Fees(0, 0, new uint256[](0)));
        }

        // calculate the amount to send in
        uint256 inputValueWithoutFee = (numItems * tokenBalance) / (nftBalance - numItems);

        // add the fees to the amount to send in
        fees.protocol = inputValueWithoutFee.fmul(feeMultipliers.protocol, FixedPointMathLib.WAD);

        fees.trade = inputValueWithoutFee.fmul(feeMultipliers.trade, FixedPointMathLib.WAD);

        // Account for the carry fee, only for Trade pools
        uint256 carryFee = fees.trade.fmul(feeMultipliers.carry, FixedPointMathLib.WAD);
        fees.trade -= carryFee;
        fees.protocol += carryFee;

        fees.royalties = new uint256[](numItems);
        // For XYK, every item has the same price so royalties have the same value
        uint256 royaltyAmount =
            (inputValueWithoutFee / numItems).fmul(feeMultipliers.royaltyNumerator, FixedPointMathLib.WAD);
        for (uint256 i = 0; i < numItems;) {
            fees.royalties[i] = royaltyAmount;

            unchecked {
                ++i;
            }
        }
        // Get the total royalties after accounting for integer division
        uint256 totalRoyalties = royaltyAmount * numItems;

        // Account for the trade fee (only for Trade pools), protocol fee, and
        // royalties
        inputValue = inputValueWithoutFee + fees.trade + fees.protocol + totalRoyalties;

        // set the new virtual reserves
        newParams.spotPrice = uint128(params.spotPrice + inputValueWithoutFee); // token reserve
        newParams.delta = uint128(nftBalance - numItems); // nft reserve

        // Keep state the same
        newParams.state = params.state;

        // If we got all the way here, no math error happened
        error = Error.OK;
    }

    /**
     * @dev See {ICurve-getSellInfo}
     */
    function getSellInfo(ICurve.Params calldata params, uint256 numItems, ICurve.FeeMultipliers calldata feeMultipliers)
        external
        pure
        override
        returns (Error error, ICurve.Params memory newParams, uint256 outputValue, ICurve.Fees memory fees)
    {
        if (numItems == 0) {
            return (Error.INVALID_NUMITEMS, ICurve.Params(0, 0, "", ""), 0, ICurve.Fees(0, 0, new uint256[](0)));
        }

        // get the pool's virtual nft and eth/erc20 balance
        uint256 tokenBalance = params.spotPrice;
        uint256 nftBalance = params.delta;

        // calculate the amount to send out
        uint256 outputValueWithoutFee = (numItems * tokenBalance) / (nftBalance + numItems);

        // subtract fees from amount to send out
        fees.protocol = outputValueWithoutFee.fmul(feeMultipliers.protocol, FixedPointMathLib.WAD);

        fees.trade = outputValueWithoutFee.fmul(feeMultipliers.trade, FixedPointMathLib.WAD);

        // Account for the carry fee, only for Trade pools
        uint256 carryFee = fees.trade.fmul(feeMultipliers.carry, FixedPointMathLib.WAD);
        fees.trade -= carryFee;
        fees.protocol += carryFee;

        fees.royalties = new uint256[](numItems);
        // For XYK, every item has the same price so royalties have the same value
        uint256 royaltyAmount =
            (outputValueWithoutFee / numItems).fmul(feeMultipliers.royaltyNumerator, FixedPointMathLib.WAD);
        for (uint256 i = 0; i < numItems;) {
            fees.royalties[i] = royaltyAmount;

            unchecked {
                ++i;
            }
        }
        // Get the total royalties after accounting for integer division
        uint256 totalRoyalties = royaltyAmount * numItems;

        // Account for the trade fee (only for Trade pools), protocol fee, and
        // royalties
        outputValue = outputValueWithoutFee - fees.trade - fees.protocol - totalRoyalties;

        // set the new virtual reserves
        newParams.spotPrice = uint128(params.spotPrice - outputValueWithoutFee); // token reserve
        newParams.delta = uint128(nftBalance + numItems); // nft reserve

        // Keep state the same
        newParams.state = params.state;

        // If we got all the way here, no math error happened
        error = Error.OK;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // First, divide z - 1 by the denominator and add 1.
            // We allow z - 1 to underflow if z is 0, because we multiply the
            // end result by 0 if z is zero, ensuring we return 0 if z is zero.
            z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                         FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function fmul(
        uint256 x,
        uint256 y,
        uint256 baseUnit
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(x == 0 || (x * y) / x == y)
            if iszero(or(iszero(x), eq(div(z, x), y))) {
                revert(0, 0)
            }

            // If baseUnit is zero this will return zero instead of reverting.
            z := div(z, baseUnit)
        }
    }

    function fdiv(
        uint256 x,
        uint256 y,
        uint256 baseUnit
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * baseUnit in z for now.
            z := mul(x, baseUnit)

            if or(
                // Revert if y is zero to ensure we don't divide by zero below.
                iszero(y),
                // Equivalent to require(x == 0 || (x * baseUnit) / x == baseUnit)
                iszero(or(iszero(x), eq(div(z, x), baseUnit)))
            ) {
                revert(0, 0)
            }

            // We ensure y is not zero above, so there is never division by zero here.
            z := div(z, y)
        }
    }

    function fpow(
        uint256 x,
        uint256 n,
        uint256 baseUnit
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    z := baseUnit
                }
                default {
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    z := baseUnit
                }
                default {
                    z := x
                }
                let half := div(baseUnit, 2)
                for {
                    n := div(n, 2)
                } n {
                    n := div(n, 2)
                } {
                    let xx := mul(x, x)
                    if iszero(eq(div(xx, x), x)) {
                        revert(0, 0)
                    }
                    let xxRound := add(xx, half)
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }
                    x := div(xxRound, baseUnit)
                    if mod(n, 2) {
                        let zx := mul(z, x)
                        if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) {
                            revert(0, 0)
                        }
                        let zxRound := add(zx, half)
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }
                        z := div(zxRound, baseUnit)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            // Start off with z at 1.
            z := 1

            // Used below to help find a nearby power of 2.
            let y := x

            // Find the lowest power of 2 that is at least sqrt(x).
            if iszero(lt(y, 0x100000000000000000000000000000000)) {
                y := shr(128, y) // Like dividing by 2 ** 128.
                z := shl(64, z) // Like multiplying by 2 ** 64.
            }
            if iszero(lt(y, 0x10000000000000000)) {
                y := shr(64, y) // Like dividing by 2 ** 64.
                z := shl(32, z) // Like multiplying by 2 ** 32.
            }
            if iszero(lt(y, 0x100000000)) {
                y := shr(32, y) // Like dividing by 2 ** 32.
                z := shl(16, z) // Like multiplying by 2 ** 16.
            }
            if iszero(lt(y, 0x10000)) {
                y := shr(16, y) // Like dividing by 2 ** 16.
                z := shl(8, z) // Like multiplying by 2 ** 8.
            }
            if iszero(lt(y, 0x100)) {
                y := shr(8, y) // Like dividing by 2 ** 8.
                z := shl(4, z) // Like multiplying by 2 ** 4.
            }
            if iszero(lt(y, 0x10)) {
                y := shr(4, y) // Like dividing by 2 ** 4.
                z := shl(2, z) // Like multiplying by 2 ** 2.
            }
            if iszero(lt(y, 0x8)) {
                // Equivalent to 2 ** z.
                z := shl(1, z)
            }

            // Shifting right by 1 is like dividing by 2.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // Compute a rounded down version of z.
            let zRoundDown := div(x, z)

            // If zRoundDown is smaller, use it.
            if lt(zRoundDown, z) {
                z := zRoundDown
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {ICurve} from "./ICurve.sol";
import {CurveErrorCodes} from "./CurveErrorCodes.sol";
import {FixedPointMathLib} from "../lib/FixedPointMathLib.sol";

import {ABDKMath64x64} from "../lib/ABDKMATH64x64.sol";

/**
 * @author potato-cat69
 * @notice Bonding curve logic for a sigmoid curve, where each buy/sell changes
 * spot price by adjusting its position along a sigmoid curve.
 *
 * WARNING: This curve does not set spotPrice to be the sell now price. Do not
 * assume as such. spotPrice for this curve is set to 0.
 *
 * GLOSSARY:
 *     P_min: minimum price of an NFT to be bought / sold
 *     P_max: maximum price of an NFT to be bought / sold
 *     k: scaling factor (curve gradient) that affects how fast P_min and P_max is approached.
 *     n_0: initial number of NFTs the pool had
 *     n: current number of NFTs the pool is holding
 *     deltaN: n - n_0, ie. the delta between initial and current NFTs held
 *
 * CONSTRAINTS:
 *     - k and deltaN must be expressible as signed 64.64 bit fixed point
 *       binary numbers as we rely on a 64x64 library for computations.
 *     - k is non-negative as it is casted from uint256 delta, implying 0 <= k <= 0x7FFFFFFFFFFFFFFF
 *     - -0x8000000000000000 <= deltaN <= 0x7FFFFFFFFFFFFFFF
 *     - This means the pool can never have a net loss of NFTs greater than
 *       -0x8000000000000000 or a net gain of NFTs greater than
 *       0x7FFFFFFFFFFFFFFF
 *
 * @dev The curve takes the form:
 * P(deltaN) = P_min + (P_max - P_min) / (1 + 2 ** (k * deltaN))
 *
 * While a traditional sigmoid uses e as the exponent base, this is equivalent
 * to modifying the value of k so a value of 2 is used for convenience.
 *
 * The values used in the equation for P(n) are as described below:
 * - `props` must be abi.encode(uint256(P_min), uint256(P_max - P_min))
 * - `state` must be abi.encode(int128(n - n0))
 * - `delta` must be k * 2**10 as a uint128. The value of k is normalized
 *   because most useful curves have k between 0 and 8, with small changes to k
 *   (e.g. 1/128) producing significant changes to the curve
 */
contract SigmoidCurve is ICurve, CurveErrorCodes {
    using FixedPointMathLib for uint256;
    using ABDKMath64x64 for int128;
    /**
     * @dev k = `(delta << 64) / 2**K_NORMALIZATION_EXPONENT`
     */

    uint256 private constant K_NORMALIZATION_EXPONENT = 10;
    int128 private constant ONE_64_64 = 1 << 64;

    /**
     * @dev See {ICurve-validateDelta}
     */
    function validateDelta(uint128 delta) external pure override returns (bool valid) {
        return valid64x64Uint(delta);
    }

    /**
     * @dev See {ICurve-validateSpotPrice}
     */
    function validateSpotPrice(uint128 /* newSpotPrice */ ) external pure override returns (bool) {
        // For a sigmoid curve, spot price is unused.
        return true;
    }

    /**
     * @dev See {ICurve-validateProps}
     */
    function validateProps(bytes calldata props) external pure returns (bool valid) {
        // The only way for P_min and deltaP to be invalid is if P_min + deltaP
        // causes overflow (i.e. P_max not in uint256 space)

        // We don't want to revert on overflow, just return false. So do
        // unchecked addition and compare. Equality is allowed because deltaP of
        // 0 is allowed. Safe because it's impossible to overflow back to the
        // same number in a single binop addition.
        (uint256 P_min, uint256 deltaP) = getPriceRange(props);

        unchecked {
            uint256 P_max = P_min + deltaP;
            return P_max >= P_min;
        }
    }

    /**
     * @dev See {ICurve-validateState}
     */
    function validateState(bytes calldata state) external pure returns (bool valid) {
        // convert to uint256 first, then check it doesn't exceed upper and lower bounds of int64
        // modified from https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol#L374-L383
        if (state.length < 32) return false;
        uint256 tempUint;
        assembly {
            tempUint := calldataload(state.offset)
        }

        // taken from OpenZeppelin's SafeCast library
        // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.8.0/contracts/utils/math/SafeCast.sol#L1131-L1135
        // Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        if (tempUint > uint256(type(int256).max)) return false;
        return valid64x64Int(int256(tempUint));
    }

    /**
     * @dev See {ICurve-getBuyInfo}
     */
    function getBuyInfo(ICurve.Params calldata params, uint256 numItems, ICurve.FeeMultipliers calldata feeMultipliers)
        external
        pure
        override
        returns (Error error, ICurve.Params memory newParams, uint256 inputValue, ICurve.Fees memory fees)
    {
        // We only calculate changes for buying 1 or more NFTs
        if (numItems == 0) {
            return (Error.INVALID_NUMITEMS, ICurve.Params(0, 0, "", ""), 0, ICurve.Fees(0, 0, new uint256[](0)));
        }

        // Extract information about the state of the pool
        (int128 k, int256 deltaN, uint256 pMin, uint256 deltaP) =
            getSigmoidParameters(params.delta, params.props, params.state);

        // First, set new spotPrice and delta equal to old spotPrice and delta
        // as neither changes for this curve
        newParams.spotPrice = params.spotPrice;
        newParams.delta = params.delta;

        // Next, it is easy to compute the new delta. Only deltaN changes as
        // it is the only stateful variable.

        // Verify that the resulting deltaN is will be valid. First ensure that
        // `numItems` fits in a 64 bit unsigned int. Then we can subtract
        // unchecked and manually check if bounds are exceeded
        if (numItems > 0x7FFFFFFFFFFFFFFF) {
            return (Error.TOO_MANY_ITEMS, ICurve.Params(0, 0, "", ""), 0, ICurve.Fees(0, 0, new uint256[](0)));
        }

        int256 _numItems = int256(numItems);
        // Ensure deltaN + _numItems can be safecasted for 64.64 bit computations
        if (!valid64x64Int(deltaN - _numItems)) {
            return (Error.TOO_MANY_ITEMS, ICurve.Params(0, 0, "", ""), 0, ICurve.Fees(0, 0, new uint256[](0)));
        }

        newParams.state = encodeState(deltaN - _numItems);

        // To avoid arbitrage, buy prices are calculated with deltaN incremented by 1
        // Iterate to calculate values. No closed form expression for discrete
        // sigmoid steps
        int128 kDeltaN;
        int128 fraction;
        uint256 itemCost; // The cost of the n-th item
        uint256 itemRoyalty; // The royalty for the n-th item

        fees.royalties = new uint256[](numItems);
        uint256 totalRoyalty;

        // Buying NFTs means no. of NFTs held by the pool is decreasing
        // Hence we decrease by n iteratively to the new price at fixedPointN for each NFT bought
        // ie. P(newDeltaN) = P_min + (P_max - P_min) / (1 + 2 ** k * newDeltaN))
        // = P_min + deltaP / (1 + 2 ** k * (deltaN - n))
        // = P_min + deltaP (1 / (1 + 2 ** k * (deltaN - n)))
        // the loop calculates the sum of (1 / (1 + 2 ** k * (deltaN - n))) before we apply scaling by deltaP
        for (int256 n = 1; n <= _numItems;) {
            kDeltaN = ABDKMath64x64.fromInt(deltaN - n).mul(k);
            // fraction = 1 / (1 + 2 ** (k * (deltaN - n)))
            fraction = ONE_64_64.div(ONE_64_64.add(kDeltaN.exp_2()));
            itemCost = pMin + fraction.mulu(deltaP);
            inputValue += itemCost;
            itemRoyalty = itemCost.fmul(feeMultipliers.royaltyNumerator, FixedPointMathLib.WAD);
            fees.royalties[uint256(n) - 1] = itemRoyalty;
            totalRoyalty += itemRoyalty;

            unchecked {
                ++n;
            }
        }

        // Account for the protocol fee, a flat percentage of the buy amount, only for Non-Trade pools
        fees.protocol = inputValue.fmul(feeMultipliers.protocol, FixedPointMathLib.WAD);

        // Account for the trade fee, only for Trade pools
        fees.trade = inputValue.fmul(feeMultipliers.trade, FixedPointMathLib.WAD);

        // Account for the carry fee, only for Trade pools
        uint256 carryFee = fees.trade.fmul(feeMultipliers.carry, FixedPointMathLib.WAD);
        fees.trade -= carryFee;
        fees.protocol += carryFee;

        // Account for the trade fee (only for Trade pools), protocol fee, and
        // royalties
        inputValue += fees.trade + fees.protocol + totalRoyalty;

        // If we got all the way here, no math error happened
        // Error defaults to Error.OK, no need assignment
    }

    /**
     * @dev See {ICurve-getSellInfo}
     */
    function getSellInfo(ICurve.Params calldata params, uint256 numItems, ICurve.FeeMultipliers calldata feeMultipliers)
        external
        pure
        returns (
            CurveErrorCodes.Error error,
            ICurve.Params memory newParams,
            uint256 outputValue,
            ICurve.Fees memory fees
        )
    {
        // We only calculate changes for selling 1 or more NFTs.
        if (numItems == 0) {
            return (Error.INVALID_NUMITEMS, ICurve.Params(0, 0, "", ""), 0, ICurve.Fees(0, 0, new uint256[](0)));
        }

        // Extract information about the state of the pool
        (int128 k, int256 deltaN, uint256 pMin, uint256 deltaP) =
            getSigmoidParameters(params.delta, params.props, params.state);

        // First, set new spotPrice and delta equal to old spotPrice and delta
        // as neither changes for this curve
        newParams.spotPrice = params.spotPrice;
        newParams.delta = params.delta;

        // Next, it is easy to compute the new delta. Only deltaN changes as
        // it is the only stateful variable.

        // Verify that the resulting deltaN is will be valid. First ensure that
        // `numItems` fits in a 64 bit unsigned int. Then we can subtract
        // unchecked and manually check if bounds are exceeded
        if (numItems > 0x7FFFFFFFFFFFFFFF) {
            return (Error.TOO_MANY_ITEMS, ICurve.Params(0, 0, "", ""), 0, ICurve.Fees(0, 0, new uint256[](0)));
        }

        int256 _numItems = int256(numItems);
        // Ensure deltaN + _numItems can be safecasted for 64.64 bit computations
        if (!valid64x64Int(deltaN + _numItems)) {
            return (Error.TOO_MANY_ITEMS, ICurve.Params(0, 0, "", ""), 0, ICurve.Fees(0, 0, new uint256[](0)));
        }

        newParams.state = encodeState(deltaN + _numItems);

        // Iterate to calculate values. No closed form expression for discrete
        // sigmoid steps
        int128 kDeltaN;
        int128 fraction;
        uint256 itemCost; // The cost of the n-th item
        uint256 itemRoyalty; // The royalty for the n-th item

        fees.royalties = new uint256[](numItems);
        uint256 totalRoyalty;

        // Selling NFTs means no. of NFTs is increasing
        // Hence we increase by n iteratively to the new price at fixedPointN for each NFT bought
        // ie. P(newDeltaN) = P_min + (P_max - P_min) / (1 + 2 ** (k * newDeltaN))
        // = P_min + deltaP / (1 + 2 ** (k * (deltaN + n)))
        // = P_min + deltaP * (1 / (1 + 2 ** (k * (deltaN + n))))
        // the loop calculates the sum of 1 / (1 + 2 ** (k * (deltaN + n))) before we apply scaling by deltaP
        for (int256 n = 1; n <= _numItems;) {
            kDeltaN = ABDKMath64x64.fromInt(n + deltaN).mul(k);
            // fraction = 1 / (1 + 2 ** (k * (deltaN + n)))
            fraction = ONE_64_64.div(ONE_64_64.add(kDeltaN.exp_2()));
            itemCost = pMin + fraction.mulu(deltaP);
            outputValue += itemCost;
            itemRoyalty = itemCost.fmul(feeMultipliers.royaltyNumerator, FixedPointMathLib.WAD);
            fees.royalties[uint256(n) - 1] = itemRoyalty;
            totalRoyalty += itemRoyalty;

            unchecked {
                ++n;
            }
        }

        // Account for the protocol fee, a flat percentage of the sell amount, only for Non-Trade pools
        fees.protocol = outputValue.fmul(feeMultipliers.protocol, FixedPointMathLib.WAD);

        // Account for the trade fee, only for Trade pools
        fees.trade = outputValue.fmul(feeMultipliers.trade, FixedPointMathLib.WAD);

        // Account for the carry fee, only for Trade pools
        uint256 carryFee = fees.trade.fmul(feeMultipliers.carry, FixedPointMathLib.WAD);
        fees.trade -= carryFee;
        fees.protocol += carryFee;

        // Account for the trade fee (only for Trade pools), protocol fee, and
        // royalties
        outputValue -= fees.trade + fees.protocol + totalRoyalty;

        // If we reached here, no math errors
        // Error defaults to Error.OK, no need assignment
    }

    /// Helper functions
    function valid64x64Uint(uint256 value) private pure returns (bool) {
        return value <= 0x7FFFFFFFFFFFFFFF;
    }

    function valid64x64Int(int256 value) private pure returns (bool) {
        return value >= -0x8000000000000000 && value <= 0x7FFFFFFFFFFFFFFF;
    }

    /**
     * @param params The params for this curve
     * @return (minPrice, maxPrice - minPrice)
     */
    function getPriceRange(bytes calldata params) private pure returns (uint256, uint256) {
        return abi.decode(params, (uint256, uint256));
    }

    /**
     * @param state The state of this curve
     * @return The signed integer value of deltaN
     */
    function getDeltaN(bytes calldata state) private pure returns (int256) {
        return abi.decode(state, (int256));
    }

    /**
     * @param deltaN The value of (n - n_0) at the moment
     * @return The encoded state of the curve
     */
    function encodeState(int256 deltaN) private pure returns (bytes memory) {
        return abi.encode(deltaN);
    }

    /**
     * @param delta The delta for this curve
     * @return The value of k for this curve, normalized, as a 64.64 bit fixed
     * point number.
     */
    function getK(uint128 delta) private pure returns (int128) {
        /// @dev Implicit upcast to uint256
        return ABDKMath64x64.fromUInt(delta) >> K_NORMALIZATION_EXPONENT;
    }

    /**
     * @param delta The delta for this curve
     * @param params The params for this curve
     * @param state The state of this curve
     * @return k The normalized value of k as a 64.64 bit signed int
     * @return deltaN The SIGNED INTEGER value of (n - n_0)
     * @return pMin The minimum value of the sigmoid curve
     * @return deltaP The difference between min and max price of the curve
     */
    function getSigmoidParameters(uint128 delta, bytes calldata params, bytes calldata state)
        private
        pure
        returns (int128 k, int256 deltaN, uint256 pMin, uint256 deltaP)
    {
        k = getK(delta);
        deltaN = getDeltaN(state);
        (pMin, deltaP) = getPriceRange(params);
    }
}

// SPDX-License-Identifier: BSD-4-Clause
/*
 * ABDK Math 64.64 Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 */
pragma solidity ^0.8.0;

/**
 * Smart contract library of mathematical functions operating with signed
 * 64.64-bit fixed point numbers.  Signed 64.64-bit fixed point number is
 * basically a simple fraction whose numerator is signed 128-bit integer and
 * denominator is 2^64.  As long as denominator is always the same, there is no
 * need to store it, thus in Solidity signed 64.64-bit fixed point numbers are
 * represented by int128 type holding only the numerator.
 */
library ABDKMath64x64 {
  /*
   * Minimum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

  /*
   * Maximum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

  /**
   * Convert signed 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromInt (int256 x) internal pure returns (int128) {
    unchecked {
      require (x >= -0x8000000000000000 && x <= 0x7FFFFFFFFFFFFFFF);
      return int128 (x << 64);
    }
  }

  /**
   * Convert signed 64.64 fixed point number into signed 64-bit integer number
   * rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64-bit integer number
   */
  function toInt (int128 x) internal pure returns (int64) {
    unchecked {
      return int64 (x >> 64);
    }
  }

  /**
   * Convert unsigned 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromUInt (uint256 x) internal pure returns (int128) {
    unchecked {
      require (x <= 0x7FFFFFFFFFFFFFFF);
      return int128 (int256 (x << 64));
    }
  }

  /**
   * Convert signed 64.64 fixed point number into unsigned 64-bit integer
   * number rounding down.  Revert on underflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return unsigned 64-bit integer number
   */
  function toUInt (int128 x) internal pure returns (uint64) {
    unchecked {
      require (x >= 0);
      return uint64 (uint128 (x >> 64));
    }
  }

  /**
   * Convert signed 128.128 fixed point number into signed 64.64-bit fixed point
   * number rounding down.  Revert on overflow.
   *
   * @param x signed 128.128-bin fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function from128x128 (int256 x) internal pure returns (int128) {
    unchecked {
      int256 result = x >> 64;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Convert signed 64.64 fixed point number into signed 128.128 fixed point
   * number.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 128.128 fixed point number
   */
  function to128x128 (int128 x) internal pure returns (int256) {
    unchecked {
      return int256 (x) << 64;
    }
  }

  /**
   * Calculate x + y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function add (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) + y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x - y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sub (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) - y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x * y rounding down.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function mul (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) * y >> 64;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x * y rounding towards zero, where x is signed 64.64 fixed point
   * number and y is signed 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y signed 256-bit integer number
   * @return signed 256-bit integer number
   */
  function muli (int128 x, int256 y) internal pure returns (int256) {
    unchecked {
      if (x == MIN_64x64) {
        require (y >= -0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF &&
          y <= 0x1000000000000000000000000000000000000000000000000);
        return -y << 63;
      } else {
        bool negativeResult = false;
        if (x < 0) {
          x = -x;
          negativeResult = true;
        }
        if (y < 0) {
          y = -y; // We rely on overflow behavior here
          negativeResult = !negativeResult;
        }
        uint256 absoluteResult = mulu (x, uint256 (y));
        if (negativeResult) {
          require (absoluteResult <=
            0x8000000000000000000000000000000000000000000000000000000000000000);
          return -int256 (absoluteResult); // We rely on overflow behavior here
        } else {
          require (absoluteResult <=
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
          return int256 (absoluteResult);
        }
      }
    }
  }

  /**
   * Calculate x * y rounding down, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y unsigned 256-bit integer number
   * @return unsigned 256-bit integer number
   */
  function mulu (int128 x, uint256 y) internal pure returns (uint256) {
    unchecked {
      if (y == 0) return 0;

      require (x >= 0);

      uint256 lo = (uint256 (int256 (x)) * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
      uint256 hi = uint256 (int256 (x)) * (y >> 128);

      require (hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      hi <<= 64;

      require (hi <=
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - lo);
      return hi + lo;
    }
  }

  /**
   * Calculate x / y rounding towards zero.  Revert on overflow or when y is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function div (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);
      int256 result = (int256 (x) << 64) / y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are signed 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x signed 256-bit integer number
   * @param y signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divi (int256 x, int256 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);

      bool negativeResult = false;
      if (x < 0) {
        x = -x; // We rely on overflow behavior here
        negativeResult = true;
      }
      if (y < 0) {
        y = -y; // We rely on overflow behavior here
        negativeResult = !negativeResult;
      }
      uint128 absoluteResult = divuu (uint256 (x), uint256 (y));
      if (negativeResult) {
        require (absoluteResult <= 0x80000000000000000000000000000000);
        return -int128 (absoluteResult); // We rely on overflow behavior here
      } else {
        require (absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return int128 (absoluteResult); // We rely on overflow behavior here
      }
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divu (uint256 x, uint256 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);
      uint128 result = divuu (x, y);
      require (result <= uint128 (MAX_64x64));
      return int128 (result);
    }
  }

  /**
   * Calculate -x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function neg (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != MIN_64x64);
      return -x;
    }
  }

  /**
   * Calculate |x|.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function abs (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != MIN_64x64);
      return x < 0 ? -x : x;
    }
  }

  /**
   * Calculate 1 / x rounding towards zero.  Revert on overflow or when x is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function inv (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != 0);
      int256 result = int256 (0x100000000000000000000000000000000) / x;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate arithmetics average of x and y, i.e. (x + y) / 2 rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function avg (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      return int128 ((int256 (x) + int256 (y)) >> 1);
    }
  }

  /**
   * Calculate geometric average of x and y, i.e. sqrt (x * y) rounding down.
   * Revert on overflow or in case x * y is negative.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function gavg (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 m = int256 (x) * int256 (y);
      require (m >= 0);
      require (m <
          0x4000000000000000000000000000000000000000000000000000000000000000);
      return int128 (sqrtu (uint256 (m)));
    }
  }

  /**
   * Calculate x^y assuming 0^0 is 1, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y uint256 value
   * @return signed 64.64-bit fixed point number
   */
  function pow (int128 x, uint256 y) internal pure returns (int128) {
    unchecked {
      bool negative = x < 0 && y & 1 == 1;

      uint256 absX = uint128 (x < 0 ? -x : x);
      uint256 absResult;
      absResult = 0x100000000000000000000000000000000;

      if (absX <= 0x10000000000000000) {
        absX <<= 63;
        while (y != 0) {
          if (y & 0x1 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x2 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x4 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x8 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          y >>= 4;
        }

        absResult >>= 64;
      } else {
        uint256 absXShift = 63;
        if (absX < 0x1000000000000000000000000) { absX <<= 32; absXShift -= 32; }
        if (absX < 0x10000000000000000000000000000) { absX <<= 16; absXShift -= 16; }
        if (absX < 0x1000000000000000000000000000000) { absX <<= 8; absXShift -= 8; }
        if (absX < 0x10000000000000000000000000000000) { absX <<= 4; absXShift -= 4; }
        if (absX < 0x40000000000000000000000000000000) { absX <<= 2; absXShift -= 2; }
        if (absX < 0x80000000000000000000000000000000) { absX <<= 1; absXShift -= 1; }

        uint256 resultShift = 0;
        while (y != 0) {
          require (absXShift < 64);

          if (y & 0x1 != 0) {
            absResult = absResult * absX >> 127;
            resultShift += absXShift;
            if (absResult > 0x100000000000000000000000000000000) {
              absResult >>= 1;
              resultShift += 1;
            }
          }
          absX = absX * absX >> 127;
          absXShift <<= 1;
          if (absX >= 0x100000000000000000000000000000000) {
              absX >>= 1;
              absXShift += 1;
          }

          y >>= 1;
        }

        require (resultShift < 64);
        absResult >>= 64 - resultShift;
      }
      int256 result = negative ? -int256 (absResult) : int256 (absResult);
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate sqrt (x) rounding down.  Revert if x < 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sqrt (int128 x) internal pure returns (int128) {
    unchecked {
      require (x >= 0);
      return int128 (sqrtu (uint256 (int256 (x)) << 64));
    }
  }

  /**
   * Calculate binary logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function log_2 (int128 x) internal pure returns (int128) {
    unchecked {
      require (x > 0);

      int256 msb = 0;
      int256 xc = x;
      if (xc >= 0x10000000000000000) { xc >>= 64; msb += 64; }
      if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
      if (xc >= 0x10000) { xc >>= 16; msb += 16; }
      if (xc >= 0x100) { xc >>= 8; msb += 8; }
      if (xc >= 0x10) { xc >>= 4; msb += 4; }
      if (xc >= 0x4) { xc >>= 2; msb += 2; }
      if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

      int256 result = msb - 64 << 64;
      uint256 ux = uint256 (int256 (x)) << uint256 (127 - msb);
      for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
        ux *= ux;
        uint256 b = ux >> 255;
        ux >>= 127 + b;
        result += bit * int256 (b);
      }

      return int128 (result);
    }
  }

  /**
   * Calculate natural logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function ln (int128 x) internal pure returns (int128) {
    unchecked {
      require (x > 0);

      return int128 (int256 (
          uint256 (int256 (log_2 (x))) * 0xB17217F7D1CF79ABC9E3B39803F2F6AF >> 128));
    }
  }

  /**
   * Calculate binary exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp_2 (int128 x) internal pure returns (int128) {
    unchecked {
      require (x < 0x400000000000000000); // Overflow

      if (x < -0x400000000000000000) return 0; // Underflow

      uint256 result = 0x80000000000000000000000000000000;

      if (x & 0x8000000000000000 > 0)
        result = result * 0x16A09E667F3BCC908B2FB1366EA957D3E >> 128;
      if (x & 0x4000000000000000 > 0)
        result = result * 0x1306FE0A31B7152DE8D5A46305C85EDEC >> 128;
      if (x & 0x2000000000000000 > 0)
        result = result * 0x1172B83C7D517ADCDF7C8C50EB14A791F >> 128;
      if (x & 0x1000000000000000 > 0)
        result = result * 0x10B5586CF9890F6298B92B71842A98363 >> 128;
      if (x & 0x800000000000000 > 0)
        result = result * 0x1059B0D31585743AE7C548EB68CA417FD >> 128;
      if (x & 0x400000000000000 > 0)
        result = result * 0x102C9A3E778060EE6F7CACA4F7A29BDE8 >> 128;
      if (x & 0x200000000000000 > 0)
        result = result * 0x10163DA9FB33356D84A66AE336DCDFA3F >> 128;
      if (x & 0x100000000000000 > 0)
        result = result * 0x100B1AFA5ABCBED6129AB13EC11DC9543 >> 128;
      if (x & 0x80000000000000 > 0)
        result = result * 0x10058C86DA1C09EA1FF19D294CF2F679B >> 128;
      if (x & 0x40000000000000 > 0)
        result = result * 0x1002C605E2E8CEC506D21BFC89A23A00F >> 128;
      if (x & 0x20000000000000 > 0)
        result = result * 0x100162F3904051FA128BCA9C55C31E5DF >> 128;
      if (x & 0x10000000000000 > 0)
        result = result * 0x1000B175EFFDC76BA38E31671CA939725 >> 128;
      if (x & 0x8000000000000 > 0)
        result = result * 0x100058BA01FB9F96D6CACD4B180917C3D >> 128;
      if (x & 0x4000000000000 > 0)
        result = result * 0x10002C5CC37DA9491D0985C348C68E7B3 >> 128;
      if (x & 0x2000000000000 > 0)
        result = result * 0x1000162E525EE054754457D5995292026 >> 128;
      if (x & 0x1000000000000 > 0)
        result = result * 0x10000B17255775C040618BF4A4ADE83FC >> 128;
      if (x & 0x800000000000 > 0)
        result = result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB >> 128;
      if (x & 0x400000000000 > 0)
        result = result * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9 >> 128;
      if (x & 0x200000000000 > 0)
        result = result * 0x10000162E43F4F831060E02D839A9D16D >> 128;
      if (x & 0x100000000000 > 0)
        result = result * 0x100000B1721BCFC99D9F890EA06911763 >> 128;
      if (x & 0x80000000000 > 0)
        result = result * 0x10000058B90CF1E6D97F9CA14DBCC1628 >> 128;
      if (x & 0x40000000000 > 0)
        result = result * 0x1000002C5C863B73F016468F6BAC5CA2B >> 128;
      if (x & 0x20000000000 > 0)
        result = result * 0x100000162E430E5A18F6119E3C02282A5 >> 128;
      if (x & 0x10000000000 > 0)
        result = result * 0x1000000B1721835514B86E6D96EFD1BFE >> 128;
      if (x & 0x8000000000 > 0)
        result = result * 0x100000058B90C0B48C6BE5DF846C5B2EF >> 128;
      if (x & 0x4000000000 > 0)
        result = result * 0x10000002C5C8601CC6B9E94213C72737A >> 128;
      if (x & 0x2000000000 > 0)
        result = result * 0x1000000162E42FFF037DF38AA2B219F06 >> 128;
      if (x & 0x1000000000 > 0)
        result = result * 0x10000000B17217FBA9C739AA5819F44F9 >> 128;
      if (x & 0x800000000 > 0)
        result = result * 0x1000000058B90BFCDEE5ACD3C1CEDC823 >> 128;
      if (x & 0x400000000 > 0)
        result = result * 0x100000002C5C85FE31F35A6A30DA1BE50 >> 128;
      if (x & 0x200000000 > 0)
        result = result * 0x10000000162E42FF0999CE3541B9FFFCF >> 128;
      if (x & 0x100000000 > 0)
        result = result * 0x100000000B17217F80F4EF5AADDA45554 >> 128;
      if (x & 0x80000000 > 0)
        result = result * 0x10000000058B90BFBF8479BD5A81B51AD >> 128;
      if (x & 0x40000000 > 0)
        result = result * 0x1000000002C5C85FDF84BD62AE30A74CC >> 128;
      if (x & 0x20000000 > 0)
        result = result * 0x100000000162E42FEFB2FED257559BDAA >> 128;
      if (x & 0x10000000 > 0)
        result = result * 0x1000000000B17217F7D5A7716BBA4A9AE >> 128;
      if (x & 0x8000000 > 0)
        result = result * 0x100000000058B90BFBE9DDBAC5E109CCE >> 128;
      if (x & 0x4000000 > 0)
        result = result * 0x10000000002C5C85FDF4B15DE6F17EB0D >> 128;
      if (x & 0x2000000 > 0)
        result = result * 0x1000000000162E42FEFA494F1478FDE05 >> 128;
      if (x & 0x1000000 > 0)
        result = result * 0x10000000000B17217F7D20CF927C8E94C >> 128;
      if (x & 0x800000 > 0)
        result = result * 0x1000000000058B90BFBE8F71CB4E4B33D >> 128;
      if (x & 0x400000 > 0)
        result = result * 0x100000000002C5C85FDF477B662B26945 >> 128;
      if (x & 0x200000 > 0)
        result = result * 0x10000000000162E42FEFA3AE53369388C >> 128;
      if (x & 0x100000 > 0)
        result = result * 0x100000000000B17217F7D1D351A389D40 >> 128;
      if (x & 0x80000 > 0)
        result = result * 0x10000000000058B90BFBE8E8B2D3D4EDE >> 128;
      if (x & 0x40000 > 0)
        result = result * 0x1000000000002C5C85FDF4741BEA6E77E >> 128;
      if (x & 0x20000 > 0)
        result = result * 0x100000000000162E42FEFA39FE95583C2 >> 128;
      if (x & 0x10000 > 0)
        result = result * 0x1000000000000B17217F7D1CFB72B45E1 >> 128;
      if (x & 0x8000 > 0)
        result = result * 0x100000000000058B90BFBE8E7CC35C3F0 >> 128;
      if (x & 0x4000 > 0)
        result = result * 0x10000000000002C5C85FDF473E242EA38 >> 128;
      if (x & 0x2000 > 0)
        result = result * 0x1000000000000162E42FEFA39F02B772C >> 128;
      if (x & 0x1000 > 0)
        result = result * 0x10000000000000B17217F7D1CF7D83C1A >> 128;
      if (x & 0x800 > 0)
        result = result * 0x1000000000000058B90BFBE8E7BDCBE2E >> 128;
      if (x & 0x400 > 0)
        result = result * 0x100000000000002C5C85FDF473DEA871F >> 128;
      if (x & 0x200 > 0)
        result = result * 0x10000000000000162E42FEFA39EF44D91 >> 128;
      if (x & 0x100 > 0)
        result = result * 0x100000000000000B17217F7D1CF79E949 >> 128;
      if (x & 0x80 > 0)
        result = result * 0x10000000000000058B90BFBE8E7BCE544 >> 128;
      if (x & 0x40 > 0)
        result = result * 0x1000000000000002C5C85FDF473DE6ECA >> 128;
      if (x & 0x20 > 0)
        result = result * 0x100000000000000162E42FEFA39EF366F >> 128;
      if (x & 0x10 > 0)
        result = result * 0x1000000000000000B17217F7D1CF79AFA >> 128;
      if (x & 0x8 > 0)
        result = result * 0x100000000000000058B90BFBE8E7BCD6D >> 128;
      if (x & 0x4 > 0)
        result = result * 0x10000000000000002C5C85FDF473DE6B2 >> 128;
      if (x & 0x2 > 0)
        result = result * 0x1000000000000000162E42FEFA39EF358 >> 128;
      if (x & 0x1 > 0)
        result = result * 0x10000000000000000B17217F7D1CF79AB >> 128;

      result >>= uint256 (int256 (63 - (x >> 64)));
      require (result <= uint256 (int256 (MAX_64x64)));

      return int128 (int256 (result));
    }
  }

  /**
   * Calculate natural exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp (int128 x) internal pure returns (int128) {
    unchecked {
      require (x < 0x400000000000000000); // Overflow

      if (x < -0x400000000000000000) return 0; // Underflow

      return exp_2 (
          int128 (int256 (x) * 0x171547652B82FE1777D0FFDA0D23A7D12 >> 128));
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return unsigned 64.64-bit fixed point number
   */
  function divuu (uint256 x, uint256 y) private pure returns (uint128) {
    unchecked {
      require (y != 0);

      uint256 result;

      if (x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        result = (x << 64) / y;
      else {
        uint256 msb = 192;
        uint256 xc = x >> 192;
        if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
        if (xc >= 0x10000) { xc >>= 16; msb += 16; }
        if (xc >= 0x100) { xc >>= 8; msb += 8; }
        if (xc >= 0x10) { xc >>= 4; msb += 4; }
        if (xc >= 0x4) { xc >>= 2; msb += 2; }
        if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

        result = (x << 255 - msb) / ((y - 1 >> msb - 191) + 1);
        require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

        uint256 hi = result * (y >> 128);
        uint256 lo = result * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

        uint256 xh = x >> 192;
        uint256 xl = x << 64;

        if (xl < lo) xh -= 1;
        xl -= lo; // We rely on overflow behavior here
        lo = hi << 128;
        if (xl < lo) xh -= 1;
        xl -= lo; // We rely on overflow behavior here

        assert (xh == hi >> 128);

        result += xl / y;
      }

      require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      return uint128 (result);
    }
  }

  /**
   * Calculate sqrt (x) rounding down, where x is unsigned 256-bit integer
   * number.
   *
   * @param x unsigned 256-bit integer number
   * @return unsigned 128-bit integer number
   */
  function sqrtu (uint256 x) private pure returns (uint128) {
    unchecked {
      if (x == 0) return 0;
      else {
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) { xx >>= 128; r <<= 64; }
        if (xx >= 0x10000000000000000) { xx >>= 64; r <<= 32; }
        if (xx >= 0x100000000) { xx >>= 32; r <<= 16; }
        if (xx >= 0x10000) { xx >>= 16; r <<= 8; }
        if (xx >= 0x100) { xx >>= 8; r <<= 4; }
        if (xx >= 0x10) { xx >>= 4; r <<= 2; }
        if (xx >= 0x8) { r <<= 1; }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return uint128 (r < r1 ? r : r1);
      }
    }
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {ICurve} from "./ICurve.sol";
import {CurveErrorCodes} from "./CurveErrorCodes.sol";
import {FixedPointMathLib} from "../lib/FixedPointMathLib.sol";

/*
    @author Collection
    @notice Bonding curve logic for a linear curve, where each buy/sell changes spot price by adding/substracting delta*/
contract LinearCurve is ICurve, CurveErrorCodes {
    using FixedPointMathLib for uint256;

    /**
     * @dev See {ICurve-validateDelta}
     */
    function validateDelta(uint128 /*delta*/ ) external pure override returns (bool valid) {
        // For a linear curve, all values of delta are valid
        return true;
    }

    /**
     * @dev See {ICurve-validateSpotPrice}
     */
    function validateSpotPrice(uint128 /* newSpotPrice */ ) external pure override returns (bool) {
        // For a linear curve, all values of spot price are valid
        return true;
    }

    /**
     * @dev See {ICurve-validateProps}
     */
    function validateProps(bytes calldata /*props*/ ) external pure override returns (bool valid) {
        // For a linear curve, all values of props are valid
        return true;
    }

    /**
     * @dev See {ICurve-validateState}
     */
    function validateState(bytes calldata /*state*/ ) external pure override returns (bool valid) {
        // For a linear curve, all values of state are valid
        return true;
    }

    /**
     * @dev See {ICurve-getBuyInfo}
     */
    function getBuyInfo(ICurve.Params calldata params, uint256 numItems, ICurve.FeeMultipliers calldata feeMultipliers)
        external
        pure
        override
        returns (Error error, ICurve.Params memory newParams, uint256 inputValue, ICurve.Fees memory fees)
    {
        // We only calculate changes for buying 1 or more NFTs
        if (numItems == 0) {
            return (Error.INVALID_NUMITEMS, ICurve.Params(0, 0, "", ""), 0, ICurve.Fees(0, 0, new uint256[](0)));
        }

        // For a linear curve, the spot price increases by delta for each item bought
        uint256 newSpotPrice_ = params.spotPrice + params.delta * numItems;
        if (newSpotPrice_ > type(uint128).max) {
            return (Error.SPOT_PRICE_OVERFLOW, ICurve.Params(0, 0, "", ""), 0, ICurve.Fees(0, 0, new uint256[](0)));
        }
        newParams.spotPrice = uint128(newSpotPrice_);

        // Spot price is assumed to be the instant sell price. To avoid arbitraging LPs, we adjust the buy price upwards.
        // If spot price for buy and sell were the same, then someone could buy 1 NFT and then sell for immediate profit.
        // EX: Let S be spot price. Then buying 1 NFT costs S ETH, now new spot price is (S+delta).
        // The same person could then sell for (S+delta) ETH, netting them delta ETH profit.
        // If spot price for buy and sell differ by delta, then buying costs (S+delta) ETH.
        // The new spot price would become (S+delta), so selling would also yield (S+delta) ETH.
        uint256 buySpotPrice = params.spotPrice + params.delta;

        // If we buy n items, then the total cost is equal to:
        // (buy spot price) + (buy spot price + 1*delta) + (buy spot price + 2*delta) + ... + (buy spot price + (n-1)*delta)
        // This is equal to n*(buy spot price) + (delta)*(n*(n-1))/2
        // because we have n instances of buy spot price, and then we sum up from delta to (n-1)*delta
        inputValue = numItems * buySpotPrice + (numItems * (numItems - 1) * params.delta) / 2;

        // Account for the protocol fee, a flat percentage of the buy amount, only for Non-Trade pools
        fees.protocol = inputValue.fmul(feeMultipliers.protocol, FixedPointMathLib.WAD);

        // Account for the trade fee, only for Trade pools
        fees.trade = inputValue.fmul(feeMultipliers.trade, FixedPointMathLib.WAD);

        // Locally scoped to avoid stack too deep
        {
            // Account for the carry fee, only for Trade pools
            uint256 carryFee = fees.trade.fmul(feeMultipliers.carry, FixedPointMathLib.WAD);
            fees.trade -= carryFee;
            fees.protocol += carryFee;
        }

        fees.royalties = new uint256[](numItems);
        uint256 totalRoyalty;
        for (uint256 i = 0; i < numItems;) {
            uint256 royaltyAmount =
                (buySpotPrice + (params.delta * i)).fmul(feeMultipliers.royaltyNumerator, FixedPointMathLib.WAD);
            fees.royalties[i] = royaltyAmount;
            totalRoyalty += royaltyAmount;

            unchecked {
                ++i;
            }
        }

        // Account for the trade fee (only for Trade pools) and protocol fee
        inputValue += fees.trade + fees.protocol + totalRoyalty;

        // Keep delta the same
        newParams.delta = params.delta;

        // Keep state the same
        newParams.state = params.state;

        // If we got all the way here, no math error happened
        error = Error.OK;
    }

    /**
     * @dev See {ICurve-getSellInfo}
     */
    function getSellInfo(ICurve.Params calldata params, uint256 numItems, ICurve.FeeMultipliers calldata feeMultipliers)
        external
        pure
        override
        returns (Error error, ICurve.Params memory newParams, uint256 outputValue, ICurve.Fees memory fees)
    {
        // We only calculate changes for selling 1 or more NFTs
        if (numItems == 0) {
            return (Error.INVALID_NUMITEMS, ICurve.Params(0, 0, "", ""), 0, ICurve.Fees(0, 0, new uint256[](0)));
        }

        // We first calculate the change in spot price after selling all of the items
        uint256 totalPriceDecrease = params.delta * numItems;

        // If the current spot price is less than the total amount that the spot price should change by...
        if (params.spotPrice < totalPriceDecrease) {
            // Then we set the new spot price to be 0. (Spot price is never negative)
            newParams.spotPrice = 0;

            // We calculate how many items we can sell into the linear curve until the spot price reaches 0, rounding up
            uint256 numItemsTillZeroPrice = params.spotPrice / params.delta + 1;
            numItems = numItemsTillZeroPrice;
        }
        // Otherwise, the current spot price is greater than or equal to the total amount that the spot price changes
        // Thus we don't need to calculate the maximum number of items until we reach zero spot price, so we don't modify numItems
        else {
            // The new spot price is just the change between spot price and the total price change
            newParams.spotPrice = params.spotPrice - uint128(totalPriceDecrease);
        }

        // If we sell n items, then the total sale amount is:
        // (spot price) + (spot price - 1*delta) + (spot price - 2*delta) + ... + (spot price - (n-1)*delta)
        // This is equal to n*(spot price) - (delta)*(n*(n-1))/2
        outputValue = numItems * params.spotPrice - (numItems * (numItems - 1) * params.delta) / 2;

        // Account for the protocol fee, a flat percentage of the sell amount, only for Non-Trade pools
        fees.protocol = outputValue.fmul(feeMultipliers.protocol, FixedPointMathLib.WAD);

        // Account for the trade fee, only for Trade pools
        fees.trade = outputValue.fmul(feeMultipliers.trade, FixedPointMathLib.WAD);

        // Account for the carry fee, only for Trade pools
        uint256 carryFee = fees.trade.fmul(feeMultipliers.carry, FixedPointMathLib.WAD);
        fees.trade -= carryFee;
        fees.protocol += carryFee;

        fees.royalties = new uint256[](numItems);
        uint256 totalRoyalty;
        for (uint256 i = 0; i < numItems;) {
            uint256 royaltyAmount =
                (params.spotPrice - (params.delta * i)).fmul(feeMultipliers.royaltyNumerator, FixedPointMathLib.WAD);
            fees.royalties[i] = royaltyAmount;
            totalRoyalty += royaltyAmount;

            unchecked {
                ++i;
            }
        }

        // Account for the trade fee (only for Trade pools), protocol fee, and
        // royalties
        outputValue -= fees.trade + fees.protocol + totalRoyalty;

        // Keep delta the same
        newParams.delta = params.delta;

        // Keep state the same
        newParams.state = params.state;

        // If we reached here, no math errors
        error = Error.OK;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {ICurve} from "./ICurve.sol";
import {CurveErrorCodes} from "./CurveErrorCodes.sol";
import {FixedPointMathLib} from "../lib/FixedPointMathLib.sol";

/*
    @author Collection
    @notice Bonding curve logic for an exponential curve, where each buy/sell changes spot price by multiplying/dividing delta*/
contract ExponentialCurve is ICurve, CurveErrorCodes {
    using FixedPointMathLib for uint256;

    // minimum price to prevent numerical issues
    uint256 public constant MIN_PRICE = 1 gwei;

    /**
     * @dev See {ICurve-validateDelta}
     */
    function validateDelta(uint128 delta) external pure override returns (bool) {
        return delta > FixedPointMathLib.WAD;
    }

    /**
     * @dev See {ICurve-validateSpotPrice}
     */
    function validateSpotPrice(uint128 newSpotPrice) external pure override returns (bool) {
        return newSpotPrice >= MIN_PRICE;
    }

    /**
     * @dev See {ICurve-validateProps}
     */
    function validateProps(bytes calldata /*props*/ ) external pure override returns (bool valid) {
        // For an exponential curve, all values of props are valid
        return true;
    }

    /**
     * @dev See {ICurve-validateState}
     */
    function validateState(bytes calldata /*state*/ ) external pure override returns (bool valid) {
        // For an exponential curve, all values of state are valid
        return true;
    }

    /**
     * @dev See {ICurve-getBuyInfo}
     */
    function getBuyInfo(ICurve.Params calldata params, uint256 numItems, ICurve.FeeMultipliers calldata feeMultipliers)
        external
        pure
        override
        returns (Error error, ICurve.Params memory newParams, uint256 inputValue, ICurve.Fees memory fees)
    {
        // NOTE: we assume delta is > 1, as checked by validateDelta()
        // We only calculate changes for buying 1 or more NFTs
        if (numItems == 0) {
            return (Error.INVALID_NUMITEMS, ICurve.Params(0, 0, "", ""), 0, ICurve.Fees(0, 0, new uint256[](0)));
        }

        uint256 deltaPowN = uint256(params.delta).fpow(numItems, FixedPointMathLib.WAD);

        // For an exponential curve, the spot price is multiplied by delta for each item bought
        uint256 newSpotPrice_ = uint256(params.spotPrice).fmul(deltaPowN, FixedPointMathLib.WAD);
        if (newSpotPrice_ > type(uint128).max) {
            return (Error.SPOT_PRICE_OVERFLOW, ICurve.Params(0, 0, "", ""), 0, ICurve.Fees(0, 0, new uint256[](0)));
        }
        newParams.spotPrice = uint128(newSpotPrice_);

        // Spot price is assumed to be the instant sell price. To avoid arbitraging LPs, we adjust the buy price upwards.
        // If spot price for buy and sell were the same, then someone could buy 1 NFT and then sell for immediate profit.
        // EX: Let S be spot price. Then buying 1 NFT costs S ETH, now new spot price is (S * delta).
        // The same person could then sell for (S * delta) ETH, netting them delta ETH profit.
        // If spot price for buy and sell differ by delta, then buying costs (S * delta) ETH.
        // The new spot price would become (S * delta), so selling would also yield (S * delta) ETH.
        uint256 buySpotPrice = uint256(params.spotPrice).fmul(params.delta, FixedPointMathLib.WAD);

        // If the user buys n items, then the total cost is equal to:
        // buySpotPrice + (delta * buySpotPrice) + (delta^2 * buySpotPrice) + ... (delta^(numItems - 1) * buySpotPrice)
        // This is equal to buySpotPrice * (delta^n - 1) / (delta - 1)
        inputValue = buySpotPrice.fmul(
            (deltaPowN - FixedPointMathLib.WAD).fdiv(params.delta - FixedPointMathLib.WAD, FixedPointMathLib.WAD),
            FixedPointMathLib.WAD
        );

        // Account for the protocol fee, a flat percentage of the buy amount, only for Non-Trade pools
        fees.protocol = inputValue.fmul(feeMultipliers.protocol, FixedPointMathLib.WAD);

        // Account for the trade fee, only for Trade pools
        fees.trade = inputValue.fmul(feeMultipliers.trade, FixedPointMathLib.WAD);

        // Locally scoped to avoid stack too deep
        {
            // Account for the carry fee, only for Trade pools
            uint256 carryFee = fees.trade.fmul(feeMultipliers.carry, FixedPointMathLib.WAD);
            fees.trade -= carryFee;
            fees.protocol += carryFee;
        }

        fees.royalties = new uint256[](numItems);
        uint256 totalRoyalty;
        for (uint256 i = 0; i < numItems;) {
            uint256 deltaPowI = uint256(params.delta).fpow(i, FixedPointMathLib.WAD);
            uint256 royaltyAmount = (buySpotPrice * deltaPowI).fmul(
                feeMultipliers.royaltyNumerator,
                FixedPointMathLib.WAD * FixedPointMathLib.WAD // (delta ^ i) is still in units of ether
            );
            fees.royalties[i] = royaltyAmount;
            totalRoyalty += royaltyAmount;

            unchecked {
                ++i;
            }
        }

        // Add the fees to the required input amount
        inputValue += fees.trade + fees.protocol + totalRoyalty;

        // Keep delta the same
        newParams.delta = params.delta;

        // Keep state the same
        newParams.state = params.state;

        // If we got all the way here, no math error happened
        error = Error.OK;
    }

    /**
     * @dev See {ICurve-getSellInfo}
     * If newSpotPrice is less than MIN_PRICE, newSpotPrice is set to MIN_PRICE instead.
     * This is to prevent the spot price from ever becoming 0, which would decouple the price
     * from the bonding curve (since 0 * delta is still 0)
     */
    function getSellInfo(ICurve.Params calldata params, uint256 numItems, ICurve.FeeMultipliers calldata feeMultipliers)
        external
        pure
        override
        returns (Error error, ICurve.Params memory newParams, uint256 outputValue, ICurve.Fees memory fees)
    {
        // NOTE: we assume delta is > 1, as checked by validateDelta()

        // We only calculate changes for buying 1 or more NFTs
        if (numItems == 0) {
            return (Error.INVALID_NUMITEMS, ICurve.Params(0, 0, "", ""), 0, ICurve.Fees(0, 0, new uint256[](0)));
        }

        uint256 invDelta = FixedPointMathLib.WAD.fdiv(params.delta, FixedPointMathLib.WAD);

        // Locally scoped to avoid stack too deep
        {
            uint256 invDeltaPowN = invDelta.fpow(numItems, FixedPointMathLib.WAD);

            // For an exponential curve, the spot price is divided by delta for each item sold
            // safe to convert newSpotPrice directly into uint128 since we know newSpotPrice <= spotPrice
            // and spotPrice <= type(uint128).max
            newParams.spotPrice = uint128(uint256(params.spotPrice).fmul(invDeltaPowN, FixedPointMathLib.WAD));
            if (newParams.spotPrice < MIN_PRICE) {
                newParams.spotPrice = uint128(MIN_PRICE);
            }

            // If the user sells n items, then the total revenue is equal to:
            // spotPrice + ((1 / delta) * spotPrice) + ((1 / delta)^2 * spotPrice) + ... ((1 / delta)^(numItems - 1) * spotPrice)
            // This is equal to spotPrice * (1 - (1 / delta^n)) / (1 - (1 / delta))
            outputValue = uint256(params.spotPrice).fmul(
                (FixedPointMathLib.WAD - invDeltaPowN).fdiv(FixedPointMathLib.WAD - invDelta, FixedPointMathLib.WAD),
                FixedPointMathLib.WAD
            );
        }

        // Account for the protocol fee, a flat percentage of the sell amount
        fees.protocol = outputValue.fmul(feeMultipliers.protocol, FixedPointMathLib.WAD);

        // Account for the trade fee, only for Trade pools
        fees.trade = outputValue.fmul(feeMultipliers.trade, FixedPointMathLib.WAD);

        // Locally scoped to avoid stack too deep
        {
            // Account for the carry fee, only for Trade pools
            uint256 carryFee = fees.trade.fmul(feeMultipliers.carry, FixedPointMathLib.WAD);
            fees.trade -= carryFee;
            fees.protocol += carryFee;
        }

        fees.royalties = new uint256[](numItems);
        uint256 totalRoyalty;
        for (uint256 i = 0; i < numItems;) {
            uint256 invDeltaPowI = invDelta.fpow(i, FixedPointMathLib.WAD);
            uint256 royaltyAmount = (params.spotPrice * invDeltaPowI).fmul(
                feeMultipliers.royaltyNumerator,
                FixedPointMathLib.WAD * FixedPointMathLib.WAD // (delta ^ i) is still in units of ether
            );
            fees.royalties[i] = royaltyAmount;
            totalRoyalty += royaltyAmount;

            unchecked {
                ++i;
            }
        }

        // Account for the trade fee (only for Trade pools), protocol fee, and
        // royalties
        outputValue -= fees.trade + fees.protocol + totalRoyalty;

        // Keep delta the same
        newParams.delta = params.delta;

        // Keep state the same
        newParams.state = params.state;

        // If we got all the way here, no math error happened
        error = Error.OK;
    }
}