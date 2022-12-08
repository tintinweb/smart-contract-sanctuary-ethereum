// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {CollectionPoolETH} from "./CollectionPoolETH.sol";
import {CollectionPoolMissingEnumerable} from "./CollectionPoolMissingEnumerable.sol";
import {ICollectionPoolFactory} from "./ICollectionPoolFactory.sol";

contract CollectionPoolMissingEnumerableETH is
    CollectionPoolMissingEnumerable,
    CollectionPoolETH
{
    function poolVariant()
        public
        pure
        override
        returns (ICollectionPoolFactory.PoolVariant)
    {
        return ICollectionPoolFactory.PoolVariant.MISSING_ENUMERABLE_ETH;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import {CollectionRouter} from "./CollectionRouter.sol";
import {ICurve} from "./bonding-curves/ICurve.sol";
import {ICollectionPool} from "./ICollectionPool.sol";

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
        uint128 initialSpotPrice;
        uint256 initialPoolBalance;
        uint256 initialNFTIDsLength;
    }

    /**
        @param merkleRoot Merkle root for NFT ID filter
        @param encodedTokenIDs Encoded list of acceptable NFT IDs
        @param initialProof Merkle multiproof for initial NFT IDs
        @param initialProofFlags Merkle multiproof flags for initial NFT IDs
     */
    struct NFTFilterParams {
        bytes32 merkleRoot;
        bytes encodedTokenIDs;
        bytes32[] initialProof;
        bool[] initialProofFlags;
    }

    /**
        @notice Creates a pool contract using EIP-1167.
        @param nft The NFT contract of the collection the pool trades
        @param bondingCurve The bonding curve for the pool to price NFTs, must be whitelisted
        @param assetRecipient The address that will receive the assets traders give during trades.
                              If set to address(0), assets will be sent to the pool address.
                              Not available to TRADE pools.
        @param receiver Receiver of the LP token generated to represent ownership of the pool
        @param poolType TOKEN, NFT, or TRADE
        @param delta The delta value used by the bonding curve. The meaning of delta depends
        on the specific curve.
        @param fee The fee taken by the LP in each trade. Can only be non-zero if _poolType is Trade.
        @param spotPrice The initial selling spot price
        @param royaltyNumerator All trades will result in `royaltyNumerator` * <trade amount> / 1e18 
        being sent to the account to which the traded NFT's royalties are awardable.
        Must be 0 if `_nft` is not IERC2981 and no recipient override is set.
        @param royaltyRecipientOverride An address to which all royalties will
        be paid to if not address(0). This overrides ERC2981 royalties set by
        the NFT creator, and allows sending royalties to arbitrary addresses
        even if a collection does not support ERC2981.
        @param initialNFTIDs The list of IDs of NFTs to transfer from the sender to the pool
        @return pool The new pool
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
        @notice Creates a pool contract using EIP-1167.
        @param token The ERC20 token used for pool swaps
        @param nft The NFT contract of the collection the pool trades
        @param bondingCurve The bonding curve for the pool to price NFTs, must be whitelisted
        @param assetRecipient The address that will receive the assets traders give during trades.
                                If set to address(0), assets will be sent to the pool address.
                                Not available to TRADE pools.
        @param receiver Receiver of the LP token generated to represent ownership of the pool
        @param poolType TOKEN, NFT, or TRADE
        @param delta The delta value used by the bonding curve. The meaning of delta depends
        on the specific curve.
        @param fee The fee taken by the LP in each trade. Can only be non-zero if _poolType is Trade.
        @param spotPrice The initial selling spot price, in ETH
        @param royaltyNumerator All trades will result in `royaltyNumerator` * <trade amount> / 1e18 
        being sent to the account to which the traded NFT's royalties are awardable.
        Must be 0 if `_nft` is not IERC2981 and no recipient override is set.
        @param royaltyRecipientOverride An address to which all royalties will
        be paid to if not address(0). This overrides ERC2981 royalties set by
        the NFT creator, and allows sending royalties to arbitrary addresses
        even if a collection does not support ERC2981.
        @param initialNFTIDs The list of IDs of NFTs to transfer from the sender to the pool
        @param initialTokenBalance The initial token balance sent from the sender to the new pool
        @return pool The new pool
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

    function routerStatus(CollectionRouter router)
        external
        view
        returns (bool allowed, bool wasEverAllowed);

    function isPool(address potentialPool, PoolVariant variant)
        external
        view
        returns (bool);

    function requireAuthorizedForToken(address spender, uint256 tokenId) external view;

    function createPoolETH(
        CreateETHPoolParams calldata params
    ) external payable returns (address pool, uint256 tokenId);

    function createPoolERC20(CreateERC20PoolParams calldata params)
        external
        returns (address pool, uint256 tokenId);

    function burn(uint256 tokenId) external;

    /**
     * @return poolParams the parameters of the pool matching `tokenId`.
     */
    function viewPoolParams(uint256 tokenId)
        external
        view
        returns (LPTokenParams721 memory poolParams);

    /**
     * @param tokenId The tokenId of the pool to validate
     * @param nftAddress The address of the NFT collection which the pool 
     * should accept
     * @param bondingCurveAddress The address of the bonding curve the pool
     * should be using
     * @param fee The maximum fee the pool should have
     * @param delta The maximum delta the pool should have
     * 
     * @return true iff the pool specified by `tokenId` has the correct
     * NFT address, bonding curve address, and has fee and delta == `fee` and
     * `delta`, respectively
     */
    function validatePoolParamsLte(
        uint256 tokenId,
        address nftAddress,
        address bondingCurveAddress,
        uint96 fee,
        uint128 delta,
        uint256 royaltyNumerator
    )
        external
        view
        returns (bool);

    /**
     * @param tokenId The tokenId of the pool to validate
     * @param nftAddress The address of the NFT collection which the pool 
     * should accept
     * @param bondingCurveAddress The address of the bonding curve the pool
     * should be using
     * @param fee The fee the pool should have
     * @param delta The delta the pool should have
     * 
     * @return true iff the pool specified by `tokenId` has the correct
     * NFT address, bonding curve address, and has fee and delta <= `fee` and
     * `delta`, respectively
     */
    function validatePoolParamsEq(
        uint256 tokenId,
        address nftAddress,
        address bondingCurveAddress,
        uint96 fee,
        uint128 delta,
        uint256 royaltyNumerator
    )
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";
import {ICollectionPool} from "./ICollectionPool.sol";
import {CollectionPool} from "./CollectionPool.sol";
import {ICollectionPoolFactory} from "./ICollectionPoolFactory.sol";
import {ICurve} from "./bonding-curves/ICurve.sol";

/**
    @title An NFT/Token pool where the token is ETH
    @author Collection
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
                payable(recipient).safeTransferETH(
                    royaltyAmount
                );
            }

            unchecked {
                ++i;
            }
        }
        

        // Transfer inputAmount ETH to assetRecipient if it's been set
        address payable _assetRecipient = getAssetRecipient();
        if (_assetRecipient != address(this)) {
            _assetRecipient.safeTransferETH(
                inputAmount - protocolFee - totalRoyaltiesPaid
            );
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
    function _payProtocolFeeFromPool(
        ICollectionPoolFactory _factory,
        uint256 protocolFee
    ) internal override {
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
    function _sendTokenOutput(
        address payable tokenRecipient,
        uint256 outputAmount,
        RoyaltyDue[] memory royaltiesDue
    ) internal override {
        // Unfortunately we need to duplicate work here
        uint256 length = royaltiesDue.length;
        uint256 totalRoyaltiesDue;
        for (uint256 i = 0; i  < length; ) {
            totalRoyaltiesDue += royaltiesDue[i].amount;
            unchecked {
                ++i;
            }
        }

        // Send ETH to caller
        if (outputAmount > 0) {
            require(
                address(this).balance >= outputAmount + tradeFee + totalRoyaltiesDue,
                "Too little ETH"
            );
            tokenRecipient.safeTransferETH(outputAmount);
        }

        for (uint256 i = 0; i < length; ) {
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
        @notice Withdraws all token owned by the pool to the owner address.
        @dev Only callable by the owner.
     */
    function withdrawAllETH() external onlyAuthorized {
        tradeFee = 0;

        _withdrawETH(address(this).balance);
    }

    /**
        @notice Withdraws a specified amount of token owned by the pool to the owner address.
        @dev Only callable by the owner.
        @param amount The amount of token to send to the owner. If the pool's balance is less than
        this value, the transaction will be reverted.
     */
    function withdrawETH(uint256 amount) external onlyAuthorized {
        require(
            address(this).balance >= amount + tradeFee,
            "Too little ETH"
        );

        _withdrawETH(amount);
    }

    /// @inheritdoc ICollectionPool
    function withdrawERC20(ERC20 a, uint256 amount)
        external
        onlyAuthorized
    {
        a.safeTransfer(msg.sender, amount);
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
        @dev All ETH transfers into the pool are accepted. This is the main method
        for the owner to top up the pool's token reserves.
     */
    receive() external payable {
        emit TokenDeposit(msg.value);
    }

    /**
        @dev All ETH transfers into the pool are accepted. This is the main method
        for the owner to top up the pool's token reserves.
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

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {ICollectionPool} from "./ICollectionPool.sol";
import {CollectionPool} from "./CollectionPool.sol";
import {CollectionRouter} from "./CollectionRouter.sol";

/**
    @title An NFT/Token pool for an NFT that does not implement ERC721Enumerable
    @author Collection
 */
abstract contract CollectionPoolMissingEnumerable is CollectionPool {
    using EnumerableSet for EnumerableSet.UintSet;

    // Used for internal ID tracking
    EnumerableSet.UintSet private idSet;

    /// @inheritdoc CollectionPool
    function _selectArbitraryNFTs(
        IERC721 ,
        uint256 numNFTs
    ) internal override returns (uint256[] memory tokenIds) {
        tokenIds = new uint256[](numNFTs);
        // We're missing enumerable, so we also update the pool's own ID set
        // NOTE: We start from last index to first index to save on gas
        uint256 lastIndex = idSet.length() - 1;
        for (uint256 i; i < numNFTs; ) {
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
    function _sendSpecificNFTsToRecipient(
        IERC721 _nft,
        address nftRecipient,
        uint256[] memory nftIds
    ) internal override {
        // Send NFTs to caller
        // If missing enumerable, update pool's own ID set
        uint256 numNFTs = nftIds.length;
        for (uint256 i; i < numNFTs; ) {
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
        for (uint256 i; i < numNFTs; ) {
            ids[i] = idSet.at(i);

            unchecked {
                ++i;
            }
        }
        return ids;
    }

    /**
        @dev When safeTransfering an ERC721 in, we add ID to the idSet
        if it's the same collection used by pool. (As it doesn't auto-track because no ERC721Enumerable)
     */
    function onERC721Received(
        address,
        address,
        uint256 id,
        bytes memory
    ) public virtual returns (bytes4) {
        IERC721 _nft = nft();
        // If it's from the pool's NFT, add the ID to ID set
        if (msg.sender == address(_nft)) {
            idSet.add(id);
        }
        return this.onERC721Received.selector;
    }

    /// @inheritdoc ICollectionPool
    function withdrawERC721(IERC721 a, uint256[] calldata nftIds)
        external
        override
        onlyAuthorized
    {
        IERC721 _nft = nft();
        uint256 numNFTs = nftIds.length;
        address owner = owner();

        // If it's not the pool's NFT, just withdraw normally
        if (a != _nft) {
            for (uint256 i; i < numNFTs; ) {
                a.safeTransferFrom(address(this), owner, nftIds[i]);

                unchecked {
                    ++i;
                }
            }
        }
        // Otherwise, withdraw and also remove the ID from the ID set
        else {
            for (uint256 i; i < numNFTs; ) {
                _nft.safeTransferFrom(address(this), msg.sender, nftIds[i]);
                idSet.remove(nftIds[i]);

                unchecked {
                    ++i;
                }
            }

            emit NFTWithdrawal();
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";
import {ICollectionPool} from "./ICollectionPool.sol";
import {CollectionPool} from "./CollectionPool.sol";
import {ICollectionPoolFactory} from "./ICollectionPoolFactory.sol";
import {CurveErrorCodes} from "./bonding-curves/CurveErrorCodes.sol";

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
        ETH swaps
     */

    /**
        @notice Swaps ETH into NFTs using multiple pools.
        @param swapList The list of pools to trade with and the number of NFTs to buy from each.
        @param ethRecipient The address that will receive the unspent ETH input
        @param nftRecipient The address that will receive the NFT output
        @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
        @return remainingValue The unspent ETH amount
     */
    function swapETHForAnyNFTs(
        PoolSwapAny[] calldata swapList,
        address payable ethRecipient,
        address nftRecipient,
        uint256 deadline
    )
        external
        payable
        checkDeadline(deadline)
        returns (uint256 remainingValue)
    {
        return
            _swapETHForAnyNFTs(swapList, msg.value, ethRecipient, nftRecipient);
    }

    /**
        @notice Swaps ETH into specific NFTs using multiple pools.
        @param swapList The list of pools to trade with and the IDs of the NFTs to buy from each.
        @param ethRecipient The address that will receive the unspent ETH input
        @param nftRecipient The address that will receive the NFT output
        @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
        @return remainingValue The unspent ETH amount
     */
    function swapETHForSpecificNFTs(
        PoolSwapSpecific[] calldata swapList,
        address payable ethRecipient,
        address nftRecipient,
        uint256 deadline
    )
        external
        payable
        checkDeadline(deadline)
        returns (uint256 remainingValue)
    {
        return
            _swapETHForSpecificNFTs(
                swapList,
                msg.value,
                ethRecipient,
                nftRecipient
            );
    }

    /**
        @notice Swaps one set of NFTs into another set of specific NFTs using multiple pools, using
        ETH as the intermediary.
        @param trade The struct containing all NFT-to-ETH swaps and ETH-to-NFT swaps.
        @param minOutput The minimum acceptable total excess ETH received
        @param ethRecipient The address that will receive the ETH output
        @param nftRecipient The address that will receive the NFT output
        @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
        @return outputAmount The total ETH received
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
        outputAmount = _swapNFTsForToken(
            trade.nftToTokenTrades,
            0,
            payable(address(this))
        );

        // Add extra value to buy NFTs
        outputAmount += msg.value;

        // Swap ETH for any NFTs
        // cost <= inputValue = outputAmount - minOutput, so outputAmount' = (outputAmount - minOutput - cost) + minOutput >= minOutput
        outputAmount =
            _swapETHForAnyNFTs(
                trade.tokenToNFTTrades,
                outputAmount - minOutput,
                ethRecipient,
                nftRecipient
            ) +
            minOutput;
    }

    /**
        @notice Swaps one set of NFTs into another set of specific NFTs using multiple pools, using
        ETH as the intermediary.
        @param trade The struct containing all NFT-to-ETH swaps and ETH-to-NFT swaps.
        @param minOutput The minimum acceptable total excess ETH received
        @param ethRecipient The address that will receive the ETH output
        @param nftRecipient The address that will receive the NFT output
        @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
        @return outputAmount The total ETH received
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
        outputAmount = _swapNFTsForToken(
            trade.nftToTokenTrades,
            0,
            payable(address(this))
        );

        // Add extra value to buy NFTs
        outputAmount += msg.value;

        // Swap ETH for specific NFTs
        // cost <= inputValue = outputAmount - minOutput, so outputAmount' = (outputAmount - minOutput - cost) + minOutput >= minOutput
        outputAmount =
            _swapETHForSpecificNFTs(
                trade.tokenToNFTTrades,
                outputAmount - minOutput,
                ethRecipient,
                nftRecipient
            ) +
            minOutput;
    }

    /**
        ERC20 swaps

        Note: All ERC20 swaps assume that a single ERC20 token is used for all the pools involved.
        Swapping using multiple tokens in the same transaction is possible, but the slippage checks
        & the return values will be meaningless, and may lead to undefined behavior.

        Note: The sender should ideally grant infinite token approval to the router in order for NFT-to-NFT
        swaps to work smoothly.
     */

    /**
        @notice Swaps ERC20 tokens into NFTs using multiple pools.
        @param swapList The list of pools to trade with and the number of NFTs to buy from each.
        @param inputAmount The amount of ERC20 tokens to add to the ERC20-to-NFT swaps
        @param nftRecipient The address that will receive the NFT output
        @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
        @return remainingValue The unspent token amount
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
        @notice Swaps ERC20 tokens into specific NFTs using multiple pools.
        @param swapList The list of pools to trade with and the IDs of the NFTs to buy from each.
        @param inputAmount The amount of ERC20 tokens to add to the ERC20-to-NFT swaps
        @param nftRecipient The address that will receive the NFT output
        @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
        @return remainingValue The unspent token amount
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
        @notice Swaps NFTs into ETH/ERC20 using multiple pools.
        @param swapList The list of pools to trade with and the IDs of the NFTs to sell to each.
        @param minOutput The minimum acceptable total tokens received
        @param tokenRecipient The address that will receive the token output
        @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
        @return outputAmount The total tokens received
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
        @notice Swaps one set of NFTs into another set of specific NFTs using multiple pools, using
        an ERC20 token as the intermediary.
        @param trade The struct containing all NFT-to-ERC20 swaps and ERC20-to-NFT swaps.
        @param inputAmount The amount of ERC20 tokens to add to the ERC20-to-NFT swaps
        @param minOutput The minimum acceptable total excess tokens received
        @param nftRecipient The address that will receive the NFT output
        @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
        @return outputAmount The total ERC20 tokens received
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
        outputAmount = _swapNFTsForToken(
            trade.nftToTokenTrades,
            0,
            payable(msg.sender)
        );

        // Add extra value to buy NFTs
        outputAmount += inputAmount;

        // Swap ERC20 for any NFTs
        // cost <= maxCost = outputAmount - minOutput, so outputAmount' = outputAmount - cost >= minOutput
        // input tokens are taken directly from msg.sender
        outputAmount =
            _swapERC20ForAnyNFTs(
                trade.tokenToNFTTrades,
                outputAmount - minOutput,
                nftRecipient
            ) +
            minOutput;
    }

    /**
        @notice Swaps one set of NFTs into another set of specific NFTs using multiple pools, using
        an ERC20 token as the intermediary.
        @param trade The struct containing all NFT-to-ERC20 swaps and ERC20-to-NFT swaps.
        @param inputAmount The amount of ERC20 tokens to add to the ERC20-to-NFT swaps
        @param minOutput The minimum acceptable total excess tokens received
        @param nftRecipient The address that will receive the NFT output
        @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
        @return outputAmount The total ERC20 tokens received
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
        outputAmount = _swapNFTsForToken(
            trade.nftToTokenTrades,
            0,
            payable(msg.sender)
        );

        // Add extra value to buy NFTs
        outputAmount += inputAmount;

        // Swap ERC20 for specific NFTs
        // cost <= maxCost = outputAmount - minOutput, so outputAmount' = outputAmount - cost >= minOutput
        // input tokens are taken directly from msg.sender
        outputAmount =
            _swapERC20ForSpecificNFTs(
                trade.tokenToNFTTrades,
                outputAmount - minOutput,
                nftRecipient
            ) +
            minOutput;
    }

    /**
        Robust Swaps
        These are "robust" versions of the NFT<>Token swap functions which will never revert due to slippage
        Instead, users specify a per-swap max cost. If the price changes more than the user specifies, no swap is attempted. This allows users to specify a batch of swaps, and execute as many of them as possible.
     */

    /**
        @dev We assume msg.value >= sum of values in maxCostPerPool
        @notice Swaps as much ETH for any NFTs as possible, respecting the per-swap max cost.
        @param swapList The list of pools to trade with and the number of NFTs to buy from each.
        @param ethRecipient The address that will receive the unspent ETH input
        @param nftRecipient The address that will receive the NFT output
        @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
        @return remainingValue The unspent token amount
     */
    function robustSwapETHForAnyNFTs(
        RobustPoolSwapAny[] calldata swapList,
        address payable ethRecipient,
        address nftRecipient,
        uint256 deadline
    )
        external
        payable
        virtual
        checkDeadline(deadline)
        returns (uint256 remainingValue)
    {
        remainingValue = msg.value;

        // Try doing each swap
        uint256 poolCost;
        CurveErrorCodes.Error error;
        uint256 numSwaps = swapList.length;
        for (uint256 i; i < numSwaps; ) {
            // Calculate actual cost per swap
            (error, , , , poolCost, , ) = swapList[i].swapInfo.pool.getBuyNFTQuote(
                swapList[i].swapInfo.numItems
            );

            // If within our maxCost and no error, proceed
            if (
                poolCost <= swapList[i].maxCost &&
                error == CurveErrorCodes.Error.OK
            ) {
                // We know how much ETH to send because we already did the math above
                // So we just send that much
                remainingValue -= swapList[i].swapInfo.pool.swapTokenForAnyNFTs{
                    value: poolCost
                }(
                    swapList[i].swapInfo.numItems,
                    poolCost,
                    nftRecipient,
                    true,
                    msg.sender
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
        @dev We assume msg.value >= sum of values in maxCostPerPool
        @param swapList The list of pools to trade with and the IDs of the NFTs to buy from each.
        @param ethRecipient The address that will receive the unspent ETH input
        @param nftRecipient The address that will receive the NFT output
        @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
        @return remainingValue The unspent token amount
     */
    function robustSwapETHForSpecificNFTs(
        RobustPoolSwapSpecific[] calldata swapList,
        address payable ethRecipient,
        address nftRecipient,
        uint256 deadline
    )
        public
        payable
        virtual
        checkDeadline(deadline)
        returns (uint256 remainingValue)
    {
        remainingValue = msg.value;
        uint256 poolCost;
        CurveErrorCodes.Error error;

        // Try doing each swap
        uint256 numSwaps = swapList.length;
        for (uint256 i; i < numSwaps; ) {
            // Calculate actual cost per swap
            (error, , , , poolCost, , ) = swapList[i].swapInfo.pool.getBuyNFTQuote(
                swapList[i].swapInfo.nftIds.length
            );

            // If within our maxCost and no error, proceed
            if (
                poolCost <= swapList[i].maxCost &&
                error == CurveErrorCodes.Error.OK
            ) {
                // We know how much ETH to send because we already did the math above
                // So we just send that much
                remainingValue -= swapList[i]
                    .swapInfo
                    .pool
                    .swapTokenForSpecificNFTs{value: poolCost}(
                    swapList[i].swapInfo.nftIds,
                    poolCost,
                    nftRecipient,
                    true,
                    msg.sender
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
        @notice Swaps as many ERC20 tokens for any NFTs as possible, respecting the per-swap max cost.
        @param swapList The list of pools to trade with and the number of NFTs to buy from each.
        @param inputAmount The amount of ERC20 tokens to add to the ERC20-to-NFT swaps
        @param nftRecipient The address that will receive the NFT output
        @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
        @return remainingValue The unspent token amount

     */
    function robustSwapERC20ForAnyNFTs(
        RobustPoolSwapAny[] calldata swapList,
        uint256 inputAmount,
        address nftRecipient,
        uint256 deadline
    )
        external
        virtual
        checkDeadline(deadline)
        returns (uint256 remainingValue)
    {
        remainingValue = inputAmount;
        uint256 poolCost;
        CurveErrorCodes.Error error;

        // Try doing each swap
        uint256 numSwaps = swapList.length;
        for (uint256 i; i < numSwaps; ) {
            // Calculate actual cost per swap
            (error, , , , poolCost, , ) = swapList[i].swapInfo.pool.getBuyNFTQuote(
                swapList[i].swapInfo.numItems
            );

            // If within our maxCost and no error, proceed
            if (
                poolCost <= swapList[i].maxCost &&
                error == CurveErrorCodes.Error.OK
            ) {
                remainingValue -= swapList[i].swapInfo.pool.swapTokenForAnyNFTs(
                        swapList[i].swapInfo.numItems,
                        poolCost,
                        nftRecipient,
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
        @notice Swaps as many ERC20 tokens for specific NFTs as possible, respecting the per-swap max cost.
        @param swapList The list of pools to trade with and the IDs of the NFTs to buy from each.
        @param inputAmount The amount of ERC20 tokens to add to the ERC20-to-NFT swaps

        @param nftRecipient The address that will receive the NFT output
        @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
        @return remainingValue The unspent token amount
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
        for (uint256 i; i < numSwaps; ) {
            // Calculate actual cost per swap
            (error, , , , poolCost, , ) = swapList[i].swapInfo.pool.getBuyNFTQuote(
                swapList[i].swapInfo.nftIds.length
            );

            // If within our maxCost and no error, proceed
            if (
                poolCost <= swapList[i].maxCost &&
                error == CurveErrorCodes.Error.OK
            ) {
                remainingValue -= swapList[i]
                    .swapInfo
                    .pool
                    .swapTokenForSpecificNFTs(
                        swapList[i].swapInfo.nftIds,
                        poolCost,
                        nftRecipient,
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
        @notice Swaps as many NFTs for tokens as possible, respecting the per-swap min output
        @param swapList The list of pools to trade with and the IDs of the NFTs to sell to each.
        @param tokenRecipient The address that will receive the token output
        @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
        @return outputAmount The total ETH/ERC20 received
     */
    function robustSwapNFTsForToken(
        RobustPoolSwapSpecificForToken[] calldata swapList,
        address payable tokenRecipient,
        uint256 deadline
    ) public virtual checkDeadline(deadline) returns (uint256 outputAmount) {
        // Try doing each swap
        uint256 numSwaps = swapList.length;
        for (uint256 i; i < numSwaps; ) {
            uint256 poolOutput;

            // Locally scoped to avoid stack too deep error
            {
                CurveErrorCodes.Error error;
                (error, , , , poolOutput, , ) = swapList[i]
                    .swapInfo
                    .pool
                    .getSellNFTQuote(swapList[i].swapInfo.nftIds.length);
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
                        swapList[i].swapInfo.proofFlags
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
        @notice Buys NFTs with ETH and sells them for tokens in one transaction
        @param params All the parameters for the swap (packed in struct to avoid stack too deep), containing:
        - ethToNFTSwapList The list of NFTs to buy
        - nftToTokenSwapList The list of NFTs to sell
        - inputAmount The max amount of tokens to send (if ERC20)
        - tokenRecipient The address that receives tokens from the NFTs sold
        - nftRecipient The address that receives NFTs
        - deadline UNIX timestamp deadline for the swap
     */
    function robustSwapETHForSpecificNFTsAndNFTsToToken(
        RobustPoolNFTsFoTokenAndTokenforNFTsTrade calldata params
    )
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
            for (uint256 i; i < numSwaps; ) {
                // Calculate actual cost per swap
                (error, , , , poolCost, , ) = params
                    .tokenToNFTTrades[i]
                    .swapInfo
                    .pool
                    .getBuyNFTQuote(
                        params.tokenToNFTTrades[i].swapInfo.nftIds.length
                    );

                // If within our maxCost and no error, proceed
                if (
                    poolCost <= params.tokenToNFTTrades[i].maxCost &&
                    error == CurveErrorCodes.Error.OK
                ) {
                    // We know how much ETH to send because we already did the math above
                    // So we just send that much
                    remainingValue -= params
                        .tokenToNFTTrades[i]
                        .swapInfo
                        .pool
                        .swapTokenForSpecificNFTs{value: poolCost}(
                        params.tokenToNFTTrades[i].swapInfo.nftIds,
                        poolCost,
                        params.nftRecipient,
                        true,
                        msg.sender
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
            for (uint256 i; i < numSwaps; ) {
                uint256 poolOutput;

                // Locally scoped to avoid stack too deep error
                {
                    CurveErrorCodes.Error error;
                    (error, , , , poolOutput, , ) = params
                        .nftToTokenTrades[i]
                        .swapInfo
                        .pool
                        .getSellNFTQuote(
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
                    outputAmount += params
                        .nftToTokenTrades[i]
                        .swapInfo
                        .pool
                        .swapNFTsForToken(
                            ICollectionPool.NFTs(
                                params.nftToTokenTrades[i].swapInfo.nftIds,
                                params.nftToTokenTrades[i].swapInfo.proof,
                                params.nftToTokenTrades[i].swapInfo.proofFlags
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
        @notice Buys NFTs with ERC20, and sells them for tokens in one transaction
        @param params All the parameters for the swap (packed in struct to avoid stack too deep), containing:
        - ethToNFTSwapList The list of NFTs to buy
        - nftToTokenSwapList The list of NFTs to sell
        - inputAmount The max amount of tokens to send (if ERC20)
        - tokenRecipient The address that receives tokens from the NFTs sold
        - nftRecipient The address that receives NFTs
        - deadline UNIX timestamp deadline for the swap
     */
    function robustSwapERC20ForSpecificNFTsAndNFTsToToken(
        RobustPoolNFTsFoTokenAndTokenforNFTsTrade calldata params
    )
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
            for (uint256 i; i < numSwaps; ) {
                // Calculate actual cost per swap
                (error, , , , poolCost, , ) = params
                    .tokenToNFTTrades[i]
                    .swapInfo
                    .pool
                    .getBuyNFTQuote(
                        params.tokenToNFTTrades[i].swapInfo.nftIds.length
                    );

                // If within our maxCost and no error, proceed
                if (
                    poolCost <= params.tokenToNFTTrades[i].maxCost &&
                    error == CurveErrorCodes.Error.OK
                ) {
                    remainingValue -= params
                        .tokenToNFTTrades[i]
                        .swapInfo
                        .pool
                        .swapTokenForSpecificNFTs(
                            params.tokenToNFTTrades[i].swapInfo.nftIds,
                            poolCost,
                            params.nftRecipient,
                            true,
                            msg.sender
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
            for (uint256 i; i < numSwaps; ) {
                uint256 poolOutput;

                // Locally scoped to avoid stack too deep error
                {
                    CurveErrorCodes.Error error;
                    (error, , , , poolOutput, , ) = params
                        .nftToTokenTrades[i]
                        .swapInfo
                        .pool
                        .getSellNFTQuote(
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
                    outputAmount += params
                        .nftToTokenTrades[i]
                        .swapInfo
                        .pool
                        .swapNFTsForToken(
                            ICollectionPool.NFTs(
                                params.nftToTokenTrades[i].swapInfo.nftIds,
                                params.nftToTokenTrades[i].swapInfo.proof,
                                params.nftToTokenTrades[i].swapInfo.proofFlags
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
        Restricted functions
     */

    /**
        @dev Allows an ERC20 pool contract to transfer ERC20 tokens directly from
        the sender, in order to minimize the number of token transfers. Only callable by an ERC20 pool.
        @param token The ERC20 token to transfer
        @param from The address to transfer tokens from
        @param to The address to transfer tokens to
        @param amount The amount of tokens to transfer
        @param variant The pool variant of the pool contract
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
            variant == ICollectionPoolFactory.PoolVariant.ENUMERABLE_ERC20 ||
                variant ==
                ICollectionPoolFactory.PoolVariant.MISSING_ENUMERABLE_ERC20,
            "Not ERC20 pool"
        );

        // transfer tokens to pool
        token.safeTransferFrom(from, to, amount);
    }

    /**
        @dev Allows a pool contract to transfer ERC721 NFTs directly from
        the sender, in order to minimize the number of token transfers. Only callable by a pool.
        @param nft The ERC721 NFT to transfer
        @param from The address to transfer tokens from
        @param to The address to transfer tokens to
        @param id The ID of the NFT to transfer
        @param variant The pool variant of the pool contract
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
        Internal functions
     */

    /**
        @param deadline The last valid time for a swap
     */
    function _checkDeadline(uint256 deadline) internal view {
        require(block.timestamp <= deadline, "Deadline passed");
    }

    /**
        @notice Internal function used to swap ETH for any NFTs
        @param swapList The list of pools and swap calldata
        @param inputAmount The total amount of ETH to send
        @param ethRecipient The address receiving excess ETH
        @param nftRecipient The address receiving the NFTs from the pools
        @return remainingValue The unspent token amount
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
        for (uint256 i; i < numSwaps; ) {
            // Calculate the cost per swap first to send exact amount of ETH over, saves gas by avoiding the need to send back excess ETH
            (error, , , , poolCost, , ) = swapList[i].pool.getBuyNFTQuote(
                swapList[i].numItems
            );

            // Require no error
            require(error == CurveErrorCodes.Error.OK, "Bonding curve error");

            // Total ETH taken from sender cannot exceed inputAmount
            // because otherwise the deduction from remainingValue will fail
            remainingValue -= swapList[i].pool.swapTokenForAnyNFTs{
                value: poolCost
            }(
                swapList[i].numItems,
                remainingValue,
                nftRecipient,
                true,
                msg.sender
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
        @notice Internal function used to swap ETH for a specific set of NFTs
        @param swapList The list of pools and swap calldata
        @param inputAmount The total amount of ETH to send
        @param ethRecipient The address receiving excess ETH
        @param nftRecipient The address receiving the NFTs from the pools
        @return remainingValue The unspent token amount
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
        for (uint256 i; i < numSwaps; ) {
            // Calculate the cost per swap first to send exact amount of ETH over, saves gas by avoiding the need to send back excess ETH
            (error, , , , poolCost, , ) = swapList[i].pool.getBuyNFTQuote(
                swapList[i].nftIds.length
            );

            // Require no errors
            require(error == CurveErrorCodes.Error.OK, "Bonding curve error");

            // Total ETH taken from sender cannot exceed inputAmount
            // because otherwise the deduction from remainingValue will fail
            remainingValue -= swapList[i].pool.swapTokenForSpecificNFTs{
                value: poolCost
            }(
                swapList[i].nftIds,
                remainingValue,
                nftRecipient,
                true,
                msg.sender
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
        @notice Internal function used to swap an ERC20 token for any NFTs
        @dev Note that we don't need to query the pool's bonding curve first for pricing data because
        we just calculate and take the required amount from the caller during swap time.
        However, we can't "pull" ETH, which is why for the ETH->NFT swaps, we need to calculate the pricing info
        to figure out how much the router should send to the pool.
        @param swapList The list of pools and swap calldata
        @param inputAmount The total amount of ERC20 tokens to send
        @param nftRecipient The address receiving the NFTs from the pools
        @return remainingValue The unspent token amount
     */
    function _swapERC20ForAnyNFTs(
        PoolSwapAny[] calldata swapList,
        uint256 inputAmount,
        address nftRecipient
    ) internal virtual returns (uint256 remainingValue) {
        remainingValue = inputAmount;

        // Do swaps
        uint256 numSwaps = swapList.length;
        for (uint256 i; i < numSwaps; ) {
            // Tokens are transferred in by the pool calling router.poolTransferERC20From
            // Total tokens taken from sender cannot exceed inputAmount
            // because otherwise the deduction from remainingValue will fail
            remainingValue -= swapList[i].pool.swapTokenForAnyNFTs(
                swapList[i].numItems,
                remainingValue,
                nftRecipient,
                true,
                msg.sender
            );

            unchecked {
                ++i;
            }
        }
    }

    /**
        @notice Internal function used to swap an ERC20 token for specific NFTs
        @dev Note that we don't need to query the pool's bonding curve first for pricing data because
        we just calculate and take the required amount from the caller during swap time.
        However, we can't "pull" ETH, which is why for the ETH->NFT swaps, we need to calculate the pricing info
        to figure out how much the router should send to the pool.
        @param swapList The list of pools and swap calldata
        @param inputAmount The total amount of ERC20 tokens to send
        @param nftRecipient The address receiving the NFTs from the pools
        @return remainingValue The unspent token amount
     */
    function _swapERC20ForSpecificNFTs(
        PoolSwapSpecific[] calldata swapList,
        uint256 inputAmount,
        address nftRecipient
    ) internal virtual returns (uint256 remainingValue) {
        remainingValue = inputAmount;

        // Do swaps
        uint256 numSwaps = swapList.length;
        for (uint256 i; i < numSwaps; ) {
            // Tokens are transferred in by the pool calling router.poolTransferERC20From
            // Total tokens taken from sender cannot exceed inputAmount
            // because otherwise the deduction from remainingValue will fail
            remainingValue -= swapList[i].pool.swapTokenForSpecificNFTs(
                swapList[i].nftIds,
                remainingValue,
                nftRecipient,
                true,
                msg.sender
            );

            unchecked {
                ++i;
            }
        }
    }

    /**
        @notice Swaps NFTs for tokens, designed to be used for 1 token at a time
        @dev Calling with multiple tokens is permitted, BUT minOutput will be
        far from enough of a safety check because different tokens almost certainly have different unit prices.
        @param swapList The list of pools and swap calldata
        @param minOutput The minimum number of tokens to be receieved from the swaps
        @param tokenRecipient The address that receives the tokens
        @return outputAmount The number of tokens to be received
     */
    function _swapNFTsForToken(
        PoolSwapSpecific[] calldata swapList,
        uint256 minOutput,
        address payable tokenRecipient
    ) internal virtual returns (uint256 outputAmount) {
        // Do swaps
        uint256 numSwaps = swapList.length;
        for (uint256 i; i < numSwaps; ) {
            // Do the swap for token and then update outputAmount
            // Note: minExpectedTokenOutput is set to 0 since we're doing an aggregate slippage check below
            outputAmount += swapList[i].pool.swapNFTsForToken(
                ICollectionPool.NFTs(
                    swapList[i].nftIds,
                    swapList[i].proof,
                    swapList[i].proofFlags
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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {ICurve} from "./bonding-curves/ICurve.sol";
import {CurveErrorCodes} from "./bonding-curves/CurveErrorCodes.sol";
import {ITokenIDFilter} from "./filter/ITokenIDFilter.sol";

interface ICollectionPool is ITokenIDFilter {
    enum PoolType {
        TOKEN,
        NFT,
        TRADE
    }

    /**
        @param ids The list of IDs of the NFTs to sell to the pool
        @param proof Merkle multiproof proving list is allowed by pool
        @param proofFlags Merkle multiproof flags for proof
    */
    struct NFTs {
        uint256[] ids;
        bytes32[] proof;
        bool[] proofFlags;
    }

    function bondingCurve() external view returns (ICurve);

    function getAllHeldIds() external view returns (uint256[] memory);

    function delta() external view returns (uint128);

    function fee() external view returns (uint96);

    function nft() external view returns (IERC721);

    function poolType() external view returns (PoolType);

    function spotPrice() external view returns (uint128);

    /**
        @notice Rescues a specified set of NFTs owned by the pool to the owner address. (onlyOwnable modifier is in the implemented function)
        @dev If the NFT is the pool's collection, we also remove it from the id tracking (if the NFT is missing enumerable).
        @param a The NFT to transfer
        @param nftIds The list of IDs of the NFTs to send to the owner
     */
    function withdrawERC721(IERC721 a, uint256[] calldata nftIds) external;

    /**
        @notice Rescues ERC20 tokens from the pool to the owner. Only callable by the owner (onlyOwnable modifier is in the implemented function).
        @param a The token to transfer
        @param amount The amount of tokens to send to the owner
     */
    function withdrawERC20(ERC20 a, uint256 amount) external;

    function withdrawERC1155(IERC1155 a, uint256[] calldata ids, uint256[] calldata amounts) external;

    function getSellNFTQuote(uint256 numNFTs) external view
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

import {CurveErrorCodes} from "./CurveErrorCodes.sol";

interface ICurve {
    /**
        @param spotPrice The current selling spot price of the pool, in tokens
        @param delta The delta parameter of the pool, what it means depends on the curve
        @param props The properties of the pool, what it means depends on the curve
        @param state The state of the pool, what it means depends on the curve
    */
    struct Params {
        uint128 spotPrice;
        uint128 delta;
        bytes props;
        bytes state;
    }

    /**
        @param trade The amount of fee to send to the pool, in tokens
        @param protocol The amount of fee to send to the protocol, in tokens
        @param royalties The amount to pay for each item in the order they
        are purchased. Always has length `numItems`.
    */
    struct Fees {
        uint256 trade;
        uint256 protocol;
        uint256[] royalties;
    }

    /**
        @param feeMultiplier Determines how much fee the LP takes from this trade, 18 decimals
        @param fees.protocolMultiplier Determines how much fee the protocol takes from this trade, 18 decimals
        @param royaltyNumerator Determines how much of the trade value is awarded as royalties. 5 decimals
        @param carryFeeMultiplier Determines how much carry fee the protocol takes from this trade, 18 decimals
    */
    struct FeeMultipliers {
        uint256 trade;
        uint256 protocol;
        uint256 royaltyNumerator;
        uint256 carry;
    }

    /**
        @notice Validates if a delta value is valid for the curve. The criteria for
        validity can be different for each type of curve, for instance ExponentialCurve
        requires delta to be greater than 1.
        @param delta The delta value to be validated
        @return valid True if delta is valid, false otherwise
     */
    function validateDelta(uint128 delta) external pure returns (bool valid);

    /**
        @notice Validates if a new spot price is valid for the curve. Spot price is generally assumed to be the immediate sell price of 1 NFT to the pool, in units of the pool's pooled token.
        @param newSpotPrice The new spot price to be set
        @return valid True if the new spot price is valid, false otherwise
     */
    function validateSpotPrice(uint128 newSpotPrice)
        external
        view
        returns (bool valid);

    /**
        @notice Validates if a props value is valid for the curve. The criteria for validity can be different for each type of curve.
        @param props The props value to be validated
        @return valid True if props is valid, false otherwise
     */
    function validateProps(bytes calldata props)
        external
        view
        returns (bool valid);

    /**
        @notice Validates if a state value is valid for the curve. The criteria for validity can be different for each type of curve.
        @param state The state value to be validated
        @return valid True if state is valid, false otherwise
     */
    function validateState(bytes calldata state)
        external
        view
        returns (bool valid);

    /**
        @notice Given the current state of the pool and the trade, computes how much the user
        should pay to purchase an NFT from the pool, the new spot price, and other values.
        @dev Do not try to optimize the length of fees.royalties; compiler
        ^0.8.0 throws a YulException if you try to use an if-guard in the sigmoid
        calculation loop due to stack depth
        @param params Parameters of the pool that affect the bonding curve.
        @param numItems The number of NFTs the user is buying from the pool
        @param feeMultipliers Determines how much fee is taken from this trade.
        @return error Any math calculation errors, only Error.OK means the returned values are valid
        @return newParams The updated parameters of the pool that affect the bonding curve.
        @return inputValue The amount that the user should pay, in tokens
        @return fees The amount of fees
     */
    function getBuyInfo(
        ICurve.Params calldata params,
        uint256 numItems,
        ICurve.FeeMultipliers calldata feeMultipliers
    )
        external
        view
        returns (
            CurveErrorCodes.Error error,
            ICurve.Params calldata newParams,
            uint256 inputValue,
            ICurve.Fees calldata fees
        );

    /**
        @notice Given the current state of the pool and the trade, computes how much the user
        should receive when selling NFTs to the pool, the new spot price, and other values.
        @dev Do not try to optimize the length of fees.royalties; compiler
        ^0.8.0 throws a YulException if you try to use an if-guard in the sigmoid
        calculation loop due to stack depth
        @param params Parameters of the pool that affect the bonding curve.
        @param numItems The number of NFTs the user is selling to the pool
        @param feeMultipliers Determines how much fee is taken from this trade.
        @return error Any math calculation errors, only Error.OK means the returned values are valid
        @return newParams The updated parameters of the pool that affect the bonding curve.
        @return outputValue The amount that the user should receive, in tokens
        @return fees The amount of fees
     */
    function getSellInfo(
        ICurve.Params calldata params,
        uint256 numItems,
        ICurve.FeeMultipliers calldata feeMultipliers
    )
        external
        view
        returns (
            CurveErrorCodes.Error error,
            ICurve.Params calldata newParams,
            uint256 outputValue,
            ICurve.Fees calldata fees
        );
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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import {ReentrancyGuard} from "./lib/ReentrancyGuard.sol";
import {ICurve} from "./bonding-curves/ICurve.sol";
import {CollectionRouter} from "./CollectionRouter.sol";
import {ICollectionPool} from "./ICollectionPool.sol";
import {ICollectionPoolFactory} from "./ICollectionPoolFactory.sol";
import {CurveErrorCodes} from "./bonding-curves/CurveErrorCodes.sol";
import {TokenIDFilter} from "./filter/TokenIDFilter.sol";
import {ERC1155Holder} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

/// @title The base contract for an NFT/TOKEN AMM pool
/// @author Collection
/// @notice This implements the core swap logic from NFT to TOKEN
abstract contract CollectionPool is
    ReentrancyGuard,
    ERC1155Holder,
    TokenIDFilter,
    ICollectionPool
{

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
    uint256 internal constant MAX_FEE = 0.90e18;

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
        @dev Use this whenever modifying the value of royaltyNumerator.
    */
    modifier validRoyaltyNumerator(
        uint256 _royaltyNumerator
    ) {
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
      @notice Called during pool creation to set initial parameters
      @dev Only called once by factory to initialize.
      We verify this by making sure that the current owner is address(0).
      The Ownable library we use disallows setting the owner to be address(0), so this condition
      should only be valid before the first initialize call.
      @param _tokenId The token id of the pool
      @param _assetRecipient The address that will receive the TOKEN or NFT sent to this pool during swaps.
      NOTE: If set to address(0), they will go to the pool itself.
      @param _delta The initial delta of the bonding curve
      @param _fee The initial % fee taken, if this is a trade pool
      @param _spotPrice The initial price to sell an asset into the pool
      @param _royaltyNumerator All trades will result in `royaltyNumerator` * <trade amount> / 1e18 
        being sent to the account to which the traded NFT's royalties are awardable.
        Must be 0 if `_nft` is not IERC2981 and no recipient override is set.
        @param _royaltyRecipientOverride An address to which all royalties will
        be paid to if not address(0). This overrides ERC2981 royalties set by
        the NFT creator, and allows sending royalties to arbitrary addresses
        even if a collection does not support ERC2981.
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
            require(
                _assetRecipient == address(0),
                "Trade pools can't set asset recipient"
            );
            fee = _fee;
        }
        require(_bondingCurve.validateDelta(_delta), "Invalid delta for curve");
        require(
            _bondingCurve.validateSpotPrice(_spotPrice),
            "Invalid new spot price for curve"
        );
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
        @notice Sets NFT token ID filter that is allowed in this pool
        @param merkleRoot Merkle root representing all allowed IDs
        @param encodedTokenIDs Opaque encoded list of token IDs
     */
    function setTokenIDFilter(bytes32 merkleRoot, bytes calldata encodedTokenIDs) external {
        require(msg.sender == address(factory()) || msg.sender == owner(), "not authorized");
        _setRootAndEmitAcceptedIDs(address(nft()), merkleRoot, encodedTokenIDs);
    }

    /**
        @notice Sends token to the pool in exchange for any `numNFTs` NFTs
        @dev To compute the amount of token to send, call bondingCurve.getBuyInfo.
        This swap function is meant for users who are ID agnostic
        @param numNFTs The number of NFTs to purchase
        @param maxExpectedTokenInput The maximum acceptable cost from the sender. If the actual
        amount is greater than this value, the transaction will be reverted.
        @param nftRecipient The recipient of the NFTs
        @param isRouter True if calling from CollectionRouter, false otherwise. Not used for
        ETH pools.
        @param routerCaller If isRouter is true, ERC20 tokens will be transferred from this address. Not used for
        ETH pools.
        @return inputAmount The amount of token used for purchase
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
            require(
                _poolType == PoolType.NFT || _poolType == PoolType.TRADE,
                "Wrong Pool type"
            );
            require(
                (numNFTs > 0) && (numNFTs <= _nft.balanceOf(address(this))),
                "Ask for > 0 and <= balanceOf NFTs"
            );
        }

        require(creationTimestamp != block.timestamp, "Trade blocked");

        // Call bonding curve for pricing information
        ICurve.Fees memory fees;
        (inputAmount, fees) = _calculateBuyInfoAndUpdatePoolParams(
            numNFTs,
            maxExpectedTokenInput,
            _bondingCurve,
            _factory
        );

        tradeFee += fees.trade;
        uint256[] memory tokenIds = _selectArbitraryNFTs(_nft, numNFTs);
        RoyaltyDue[] memory royaltiesDue = _getRoyaltiesDue(_nft, tokenIds, fees.royalties);
        
        _pullTokenInputAndPayProtocolFee(
            inputAmount,
            isRouter,
            routerCaller,
            _factory,
            fees.protocol,
            royaltiesDue
        );

        _sendSpecificNFTsToRecipient(_nft, nftRecipient, tokenIds);

        _refundTokenToSender(inputAmount);

        emit SwapNFTOutPool();
    }

    /**
        @notice Sends token to the pool in exchange for a specific set of NFTs
        @dev To compute the amount of token to send, call bondingCurve.getBuyInfo
        This swap is meant for users who want specific IDs. Also higher chance of
        reverting if some of the specified IDs leave the pool before the swap goes through.
        @param nftIds The list of IDs of the NFTs to purchase
        @param maxExpectedTokenInput The maximum acceptable cost from the sender. If the actual
        amount is greater than this value, the transaction will be reverted.
        @param nftRecipient The recipient of the NFTs
        @param isRouter True if calling from CollectionRouter, false otherwise. Not used for
        ETH pools.
        @param routerCaller If isRouter is true, ERC20 tokens will be transferred from this address. Not used for
        ETH pools.
        @return inputAmount The amount of token used for purchase
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
            require(
                _poolType == PoolType.NFT || _poolType == PoolType.TRADE,
                "Wrong Pool type"
            );
            require((nftIds.length > 0), "Must ask for > 0 NFTs");
        }

        require(creationTimestamp != block.timestamp, "Trade blocked");

        // Call bonding curve for pricing information
        ICurve.Fees memory fees;
        (inputAmount, fees) = _calculateBuyInfoAndUpdatePoolParams(
            nftIds.length,
            maxExpectedTokenInput,
            _bondingCurve,
            _factory
        );

        tradeFee += fees.trade;
        RoyaltyDue[] memory royaltiesDue = _getRoyaltiesDue(nft(), nftIds, fees.royalties);

        _pullTokenInputAndPayProtocolFee(
            inputAmount,
            isRouter,
            routerCaller,
            _factory,
            fees.protocol,
            royaltiesDue
        );

        _sendSpecificNFTsToRecipient(nft(), nftRecipient, nftIds);

        _refundTokenToSender(inputAmount);

        emit SwapNFTOutPool();
    }

    /**
        @notice Sends a set of NFTs to the pool in exchange for token
        @dev To compute the amount of token to that will be received, call bondingCurve.getSellInfo.
        @param nfts The list of IDs of the NFTs to sell to the pool along with its Merkle multiproof.
        @param minExpectedTokenOutput The minimum acceptable token received by the sender. If the actual
        amount is less than this value, the transaction will be reverted.
        @param tokenRecipient The recipient of the token output
        @param isRouter True if calling from CollectionRouter, false otherwise. Not used for
        ETH pools.
        @param routerCaller If isRouter is true, ERC20 tokens will be transferred from this address. Not used for
        ETH pools.
        @return outputAmount The amount of token received
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
            require(
                _poolType == PoolType.TOKEN || _poolType == PoolType.TRADE,
                "Wrong Pool type"
            );
            require(nfts.ids.length > 0, "Must ask for > 0 NFTs");
            require(acceptsTokenIDs(nfts.ids, nfts.proof, nfts.proofFlags), "NFT not allowed");
        }

        // Call bonding curve for pricing information
        ICurve.Fees memory fees;
        (outputAmount, fees) = _calculateSellInfoAndUpdatePoolParams(
            nfts.ids.length,
            minExpectedTokenOutput,
            _bondingCurve
        );

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
        @notice Checks if NFTs is allowed in this pool
        @param tokenID NFT ID
        @param proof Merkle proof
     */
    function acceptsTokenID(uint256 tokenID, bytes32[] calldata proof) public view returns (bool) {
        return _acceptsTokenID(tokenID, proof);
    }

    /**
        @notice Checks if list of NFTs are allowed in this pool using Merkle multiproof and flags
        @param tokenIDs List of NFT IDs
        @param proof Merkle multiproof
        @param proofFlags Merkle multiproof flags
     */
    function acceptsTokenIDs(uint256[] calldata tokenIDs, bytes32[] calldata proof, bool[] calldata proofFlags) public view returns (bool) {
        return _acceptsTokenIDs(tokenIDs, proof, proofFlags);
    }

    /**
        @dev Used as read function to query the bonding curve for buy pricing info
        @param numNFTs The number of NFTs to buy from the pool
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
        (
            error,
            newParams,
            inputAmount,
            fees
        ) = bondingCurve().getBuyInfo(
            curveParams(),
            numNFTs,
            feeMultipliers()
        );

        newSpotPrice = newParams.spotPrice;
        newDelta = newParams.delta;
        newState = newParams.state;

        _tradeFee = fees.trade;
        protocolFee = fees.protocol;
    }

    /**
        @dev Used as read function to query the bonding curve for sell pricing info
        @param numNFTs The number of NFTs to sell to the pool
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
        (
            error,
            newParams,
            outputAmount,
            fees
        ) = bondingCurve().getSellInfo(
            curveParams(),
            numNFTs,
            feeMultipliers()
        );

        newSpotPrice = newParams.spotPrice;
        newDelta = newParams.delta;
        newState = newParams.state;

        _tradeFee = fees.trade;
        protocolFee = fees.protocol;
    }

    /**
        @notice Returns all NFT IDs held by the pool
     */
    function getAllHeldIds() external view virtual returns (uint256[] memory);

    /**
        @notice Returns the pool's variant (NFT is enumerable or not, pool uses ETH or ERC20)
     */
    function poolVariant()
        public
        pure
        virtual
        returns (ICollectionPoolFactory.PoolVariant);

    function factory() public pure returns (ICollectionPoolFactory _factory) {
        uint256 paramsLength = _immutableParamsLength();
        assembly {
            _factory := shr(
                0x60,
                calldataload(sub(calldatasize(), paramsLength))
            )
        }
    }

    /**
        @notice Returns the type of bonding curve that parameterizes the pool
     */
    function bondingCurve() public pure returns (ICurve _bondingCurve) {
        uint256 paramsLength = _immutableParamsLength();
        assembly {
            _bondingCurve := shr(
                0x60,
                calldataload(add(sub(calldatasize(), paramsLength), 20))
            )
        }
    }

    /**
        @notice Returns the NFT collection that parameterizes the pool
     */
    function nft() public pure returns (IERC721 _nft) {
        uint256 paramsLength = _immutableParamsLength();
        assembly {
            _nft := shr(
                0x60,
                calldataload(add(sub(calldatasize(), paramsLength), 40))
            )
        }
    }

    /**
        @notice Returns the pool's type (TOKEN/NFT/TRADE)
     */
    function poolType() public pure returns (PoolType _poolType) {
        uint256 paramsLength = _immutableParamsLength();
        assembly {
            _poolType := shr(
                0xf8,
                calldataload(add(sub(calldatasize(), paramsLength), 60))
            )
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
    function getRoyaltyRecipient(address payable erc2981Recipient) 
        internal 
        view 
        returns (address payable) 
    {
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
        @notice Returns the address that assets that receives assets when a swap is done with this pool
        Can be set to another address by the owner, if set to address(0), defaults to the pool's own address
     */
    function getAssetRecipient()
        public
        view
        returns (address payable _assetRecipient)
    {
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
        return ICurve.Params(
            spotPrice,
            delta,
            props,
            state
        );
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

        return ICurve.FeeMultipliers(
            fee,
            protocolFeeMultiplier,
            royaltyNumerator,
            carryFeeMultiplier
        );
    }

    /**
     * Internal functions
     */

    /**
        @notice Calculates the amount needed to be sent into the pool for a buy and adjusts spot price or delta if necessary
        @param numNFTs The amount of NFTs to purchase from the pool
        @param maxExpectedTokenInput The maximum acceptable cost from the sender. If the actual
        amount is greater than this value, the transaction will be reverted.
        @return inputAmount The amount of tokens total tokens receive
        @return fees The amount of tokens to send as fees
     */
    function _calculateBuyInfoAndUpdatePoolParams(
        uint256 numNFTs,
        uint256 maxExpectedTokenInput,
        ICurve _bondingCurve,
        ICollectionPoolFactory
    ) internal returns (
        uint256 inputAmount,
        ICurve.Fees memory fees
    ) {
        CurveErrorCodes.Error error;
        ICurve.Params memory params = curveParams();
        ICurve.Params memory newParams;
        (
            error,
            newParams,
            inputAmount,
            fees
        ) = _bondingCurve.getBuyInfo(
            params,
            numNFTs,
            feeMultipliers()
        );

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
        @notice Calculates the amount needed to be sent by the pool for a sell and adjusts spot price or delta if necessary
        @param numNFTs The amount of NFTs to send to the the pool
        @param minExpectedTokenOutput The minimum acceptable token received by the sender. If the actual
        amount is less than this value, the transaction will be reverted.
        @param _bondingCurve The bonding curve used to fetch pricing information from
        @return outputAmount The amount of tokens total tokens receive
        @return fees The amount of tokens to send as fees
     */
    function _calculateSellInfoAndUpdatePoolParams(
        uint256 numNFTs,
        uint256 minExpectedTokenOutput,
        ICurve _bondingCurve
    ) internal returns (
        uint256 outputAmount,
        ICurve.Fees memory fees
    ) {
        CurveErrorCodes.Error error;
        ICurve.Params memory params = curveParams();
        ICurve.Params memory newParams;
        (
            error,
            newParams,
            outputAmount,
            fees
        ) = _bondingCurve.getSellInfo(
            params,
            numNFTs,
            feeMultipliers()
        );

        // Revert if bonding curve had an error
        if (error != CurveErrorCodes.Error.OK) {
            revert BondingCurveError(error);
        }

        // Revert if output is too little
        require(
            outputAmount >= minExpectedTokenOutput,
            "Out too little tokens"
        );

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
        @notice Pulls the token input of a trade from the trader and pays the protocol fee.
        @param inputAmount The amount of tokens to be sent
        @param isRouter Whether or not the caller is CollectionRouter
        @param routerCaller If called from CollectionRouter, store the original caller
        @param _factory The CollectionPoolFactory which stores CollectionRouter allowlist info
        @param protocolFee The protocol fee to be paid
        @param royaltyAmounts An array of royalties to pay
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
        @notice Sends excess tokens back to the caller (if applicable)
        @dev We send ETH back to the caller even when called from CollectionRouter because we do an aggregate slippage check for certain bulk swaps. (Instead of sending directly back to the router caller)
        Excess ETH sent for one swap can then be used to help pay for the next swap.
     */
    function _refundTokenToSender(uint256 inputAmount) internal virtual;

    /**
        @notice Sends protocol fee (if it exists) back to the CollectionPoolFactory from the pool
     */
    function _payProtocolFeeFromPool(
        ICollectionPoolFactory _factory,
        uint256 protocolFee
    ) internal virtual;

    /**
        @notice Sends tokens to a recipient and pays royalties owed
        @param tokenRecipient The address receiving the tokens
        @param outputAmount The amount of tokens to send
        @param royaltiesDue An array of royalties to pay
     */
    function _sendTokenOutput(
        address payable tokenRecipient,
        uint256 outputAmount,
        RoyaltyDue[] memory royaltiesDue
    ) internal virtual;

    /**
     * @notice Select arbitrary NFTs from pool
     * @param _nft The address of the NFT to send
     * @param numNFTs The number of NFTs to send  
     */
    function _selectArbitraryNFTs(
        IERC721 _nft,
        uint256 numNFTs
    ) internal virtual returns (uint256[] memory tokenIds);

    /**
        @notice Sends specific NFTs to a recipient address
        @dev Even though we specify the NFT address here, this internal function is only
        used to send NFTs associated with this specific pool.
        @param _nft The address of the NFT to send
        @param nftRecipient The receiving address for the NFTs
        @param nftIds The specific IDs of NFTs to send
     */
    function _sendSpecificNFTsToRecipient(
        IERC721 _nft,
        address nftRecipient,
        uint256[] memory nftIds
    ) internal virtual;

    /**
        @notice Takes NFTs from the caller and sends them into the pool's asset recipient
        @dev This is used by the CollectionPool's swapNFTForToken function.
        @param _nft The NFT collection to take from
        @param nftIds The specific NFT IDs to take
        @param isRouter True if calling from CollectionRouter, false otherwise. Not used for
        ETH pools.
        @param routerCaller If isRouter is true, ERC20 tokens will be transferred from this address. Not used for
        ETH pools.
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
                (bool routerAllowed, ) = _factory.routerStatus(router);
                require(routerAllowed, "Not router");

                // Call router to pull NFTs
                // If more than 1 NFT is being transfered, we can do a balance check instead of an ownership check, as pools are indifferent between NFTs from the same collection
                if (numNFTs > 1) {
                    uint256 beforeBalance = _nft.balanceOf(_assetRecipient);
                    for (uint256 i = 0; i < numNFTs; ) {
                        router.poolTransferNFTFrom(
                            _nft,
                            routerCaller,
                            _assetRecipient,
                            nftIds[i],
                            poolVariant()
                        );

                        unchecked {
                            ++i;
                        }
                    }
                    require(
                        (_nft.balanceOf(_assetRecipient) - beforeBalance) ==
                            numNFTs,
                        "NFTs not transferred"
                    );
                } else {
                    router.poolTransferNFTFrom(
                        _nft,
                        routerCaller,
                        _assetRecipient,
                        nftIds[0],
                        poolVariant()
                    );
                    require(
                        _nft.ownerOf(nftIds[0]) == _assetRecipient,
                        "NFT not transferred"
                    );
                }
            } else {
                // Pull NFTs directly from sender
                for (uint256 i; i < numNFTs; ) {
                    _nft.safeTransferFrom(
                        msg.sender,
                        _assetRecipient,
                        nftIds[i]
                    );

                    unchecked {
                        ++i;
                    }
                }
            }
        }
    }

    /**
        @dev Used internally to grab pool parameters from calldata, see CollectionPoolCloner for technical details
     */
    function _immutableParamsLength() internal pure virtual returns (uint256);

    /**
     * Owner functions
     */

    /**
        @notice Rescues ERC1155 tokens from the pool to the owner. Only callable by the owner.
        @param a The NFT to transfer
        @param ids The NFT ids to transfer
        @param amounts The amounts of each id to transfer
     */
    function withdrawERC1155(
        IERC1155 a,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external onlyAuthorized {
        a.safeBatchTransferFrom(address(this), owner(), ids, amounts, "");
    }

    /**
        @notice Withdraws trade fee owned by the pool to the owner address.
        @dev Only callable by the owner.
     */
    function withdrawTradeFee() external virtual;

    /**
        @notice Updates the selling spot price. Only callable by the owner.
        @param newSpotPrice The new selling spot price value, in Token
     */
    function changeSpotPrice(uint128 newSpotPrice) external onlyOwner {
        ICurve _bondingCurve = bondingCurve();
        require(
            _bondingCurve.validateSpotPrice(newSpotPrice),
            "Invalid new spot price for curve"
        );
        if (spotPrice != newSpotPrice) {
            spotPrice = newSpotPrice;
            emit SpotPriceUpdate(newSpotPrice);
        }
    }

    /**
        @notice Updates the delta parameter. Only callable by the owner.
        @param newDelta The new delta parameter
     */
    function changeDelta(uint128 newDelta) external onlyOwner {
        ICurve _bondingCurve = bondingCurve();
        require(
            _bondingCurve.validateDelta(newDelta),
            "Invalid delta for curve"
        );
        if (delta != newDelta) {
            delta = newDelta;
            emit DeltaUpdate(newDelta);
        }
    }

    /**
        @notice Updates the props parameter. Only callable by the owner.
        @param newProps The new props parameter
     */
    function changeProps(bytes calldata newProps) external onlyOwner {
        ICurve _bondingCurve = bondingCurve();
        require(
            _bondingCurve.validateProps(newProps),
            "Invalid props for curve"
        );
        if (keccak256(props) != keccak256(newProps)) {
            props = newProps;
            emit PropsUpdate(newProps);
        }
    }

    /**
        @notice Updates the state parameter. Only callable by the owner.
        @param newState The new state parameter
     */
    function changeState(bytes calldata newState) external onlyOwner {
        ICurve _bondingCurve = bondingCurve();
        require(
            _bondingCurve.validateState(newState),
            "Invalid state for curve"
        );
        if (keccak256(state) != keccak256(newState)) {
            state = newState;
            emit StateUpdate(newState);
        }
    }

    /**
        @notice Updates the fee taken by the LP. Only callable by the owner.
        Only callable if the pool is a Trade pool. Reverts if the fee is >=
        MAX_FEE.
        @param newFee The new LP fee percentage, 18 decimals
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
        @notice Changes the address that will receive assets received from
        trades. Only callable by the owner.
        @param newRecipient The new asset recipient
     */
    function changeAssetRecipient(address payable newRecipient)
        external
        onlyOwner
    {
        PoolType _poolType = poolType();
        require(_poolType != PoolType.TRADE, "Not for Trade pools");
        if (assetRecipient != newRecipient) {
            assetRecipient = newRecipient;
            emit AssetRecipientChange(newRecipient);
        }
    }

    function changeRoyaltyNumerator(uint256 newRoyaltyNumerator) external onlyOwner validRoyaltyNumerator(newRoyaltyNumerator) {
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
        @notice Allows the pool to make arbitrary external calls to contracts
        whitelisted by the protocol. Only callable by authorized parties.
        @param target The contract to call
        @param data The calldata to pass to the contract
     */
    function call(address payable target, bytes calldata data)
        external
        onlyAuthorized
    {
        ICollectionPoolFactory _factory = factory();
        require(_factory.callAllowed(target), "Target must be whitelisted");
        (bool result, ) = target.call{value: 0}(data);
        require(result, "Call failed");
    }

    /**
        @notice Allows owner to batch multiple calls, forked from: https://github.com/boringcrypto/BoringSolidity/blob/master/contracts/BoringBatchable.sol
        @dev Intended for withdrawing/altering pool pricing in one tx, only callable by owner, cannot change owner
        @param calls The calldata for each call to make
        @param revertOnFail Whether or not to revert the entire tx if any of the calls fail
     */
    function multicall(bytes[] calldata calls, bool revertOnFail)
        external
        onlyAuthorized
    {
        for (uint256 i; i < calls.length; ) {
            (bool success, bytes memory result) = address(this).delegatecall(
                calls[i]
            );
            if (!success && revertOnFail) {
                revert(_getRevertMsg(result));
            }

            unchecked {
                ++i;
            }
        }

        // Prevent multicall from malicious frontend sneaking in ownership change
        require(
            owner() == msg.sender,
            "Ownership cannot be changed in multicall"
        );
    }

    /**
      @param _returnData The data returned from a multicall result
      @dev Used to grab the revert string from the underlying call
     */
    function _getRevertMsg(bytes memory _returnData)
        internal
        pure
        returns (string memory)
    {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }

    function _getRoyaltiesDue(
        IERC721 _nft, 
        uint256[] memory nftIds, 
        uint256[] memory royaltyAmounts
    ) private view returns (RoyaltyDue[] memory royaltiesDue) {
        uint256 length = royaltyAmounts.length;
        royaltiesDue = new RoyaltyDue[](length);
        if (royaltyNumerator != 0) {
            /// Implies that the token supports IERC2981
            for (uint256 i = 0; i < length; ) {
                address recipient;
                (recipient, ) = IERC2981(address(_nft)).royaltyInfo(nftIds[i], 0);
                royaltiesDue[i] = RoyaltyDue({
                    amount: royaltyAmounts[i], recipient: recipient
                });

                unchecked {
                    ++i;
                }
            }
        }
    }

    /**
        @notice Returns true if it's valid to set the contract variables to the
        variables passed to this function.
     */
    function _validRoyaltyState(
        uint256 _royaltyNumerator,
        address payable _royaltyRecipientOverride,
        IERC721 _nft
    ) internal view returns (bool) {
        return (
            // Supports 2981 interface to tell us who gets royalties or
            IERC165(_nft).supportsInterface(_INTERFACE_ID_ERC2981) || 
            // There is an override so we always know where to send royaltiers or
            _royaltyRecipientOverride != address(0) ||
            // Royalties will not be paid
            _royaltyNumerator == 0
        );
    }
}

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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface ITokenIDFilter {
    function tokenIDFilterRoot() external view returns (bytes32);
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {ITokenIDFilter} from "./ITokenIDFilter.sol";

contract TokenIDFilter is ITokenIDFilter {
    event AcceptsTokenIDs(address indexed _collection, bytes32 indexed _root, bytes _data);

    // Merkle root
    bytes32 public tokenIDFilterRoot;

    uint32[999] _padding;

    function _setRootAndEmitAcceptedIDs(
        address collection,
        bytes32 root,
        bytes calldata data
    ) internal {
        tokenIDFilterRoot = root;
        emit AcceptsTokenIDs(collection, tokenIDFilterRoot, data);
    }

    function _acceptsTokenID(uint256 tokenID, bytes32[] calldata proof)
    internal view returns (bool)
    {
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

    function _acceptsTokenIDs(uint256[] calldata tokenIDs, bytes32[] calldata proof, bool[] calldata proofFlags)
    internal view returns (bool)
    {
        if (tokenIDFilterRoot == 0) {
            return true;
        }

        uint length = tokenIDs.length;
        bytes32[] memory leaves = new bytes32[](length);

        for (uint i; i < length;) {
            // double hash to prevent second preimage attack
            leaves[i] = keccak256(abi.encodePacked(keccak256(abi.encodePacked((tokenIDs[i])))));
            unchecked { ++i; }
        }

        return MerkleProof.multiProofVerify(proof, proofFlags, tokenIDFilterRoot, leaves);
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