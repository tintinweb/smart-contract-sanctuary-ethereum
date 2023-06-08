// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

import { Fee } from "../../../struct/Fee.sol";
import { NftCostData } from "../../../struct/NftCostData.sol";
import { IDittoPool } from "../../../interface/IDittoPool.sol";
import { DittoPool } from "../../DittoPool.sol";
import { CurveErrorCode } from "../../../utils/CurveErrorCode.sol";
import { DittoPoolTrade } from "../../DittoPoolTrade.sol";

contract DittoPoolLin is DittoPool {
    ///@inheritdoc IDittoPool
    function bondingCurve() public pure override (IDittoPool) returns (string memory curve) {
        return "Curve: LIN";
    }

    /**
     * @dev See {DittPool-_validateDelta}
     */
    function _invalidDelta(uint128 /*delta*/ ) internal pure override returns (bool valid) {
        // For a linear curve, all values of delta are valid
        return false;
    }

    /**
     * @dev See {DittPool-_validateBasePrice}
     */
    function _invalidBasePrice(uint128 newBasePrice)
        internal
        pure
        override
        returns (bool)
    {
        // For a linear curve, all values of base price are valid
        return newBasePrice == 0;
    }

    /**
     * @dev See {DittPool-_getBuyInfo}
     */
    function _getBuyInfo(
        uint128 basePrice,
        uint128 delta,
        uint256 numItems,
        bytes calldata /*swapData*/,
        Fee memory fee_
    )
        internal
        pure
        virtual
        override
        returns (
            CurveErrorCode error,
            uint128 newBasePrice,
            uint128 newDelta,
            uint256 inputValue,
            NftCostData[] memory nftCostData
        )
    {
        // We only calculate changes for buying 1 or more NFTs
        if (numItems == 0) {
            return (CurveErrorCode.INVALID_NUMITEMS, 0, 0, 0, nftCostData);
        }

        // For a linear curve, the base price increases by delta for each item bought
        uint256 newBasePrice_ = basePrice + delta * numItems;
        if (newBasePrice_ > type(uint128).max) {
            return (CurveErrorCode.BASE_PRICE_OVERFLOW, 0, 0, 0, nftCostData);
        }
        newBasePrice = uint128(newBasePrice_);

        // Spot price is assumed to be the instant sell price. To avoid arbitraging LPs, we adjust the buy price upwards.
        // If base price for buy and sell were the same, then someone could buy 1 NFT and then sell for immediate profit.
        // EX: Let S be base price. Then buying 1 NFT costs S ETH, now new base price is (S+delta).
        // The same person could then sell for (S+delta) ETH, netting them delta ETH profit.
        // If base price for buy and sell differ by delta, then buying costs (S+delta) ETH.
        // The new base price would become (S+delta), so selling would also yield (S+delta) ETH.
        uint256 buyBasePrice = basePrice + delta;

        // If we buy n items, then the total cost is equal to:
        // (buy base price) + (buy base price + 1*delta) + (buy base price + 2*delta) + ... + (buy base price + (n-1)*delta)
        // This is equal to n*(buy base price) + (delta)*(n*(n-1))/2
        // because we have n instances of buy base price, and then we sum up from delta to (n-1)*delta
        inputValue = numItems * buyBasePrice + (numItems * (numItems - 1) * delta) / 2;
        
        uint256 totalFees;
        (totalFees, nftCostData) = _calculateUniformNftCostData(inputValue, numItems, fee_);

        inputValue += totalFees;

        // Keep delta the same
        newDelta = delta;

        // If we got all the way here, no math error happened
        error = CurveErrorCode.OK;
    }

    /**
     *  @dev See {DittPool-_getSellInfo}
     */
    function _getSellInfo(
        uint128 basePrice,
        uint128 delta,
        uint256 numItems,
        bytes calldata /*swapData_*/,
        Fee memory fee_
    )
        internal
        pure
        virtual
        override
        returns (
            CurveErrorCode error,
            uint128 newBasePrice,
            uint128 newDelta,
            uint256 outputValue,
            NftCostData[] memory nftCostData
        )
    {
        // We only calculate changes for selling 1 or more NFTs
        if (numItems == 0) {
            return (CurveErrorCode.INVALID_NUMITEMS, 0, 0, 0, nftCostData);
        }

        // We first calculate the change in base price after selling all of the items
        uint256 totalPriceDecrease = delta * numItems;

        // If the current base price is less than the total amount that the base price should change by...
        if (basePrice < totalPriceDecrease) {
            return (CurveErrorCode.INVALID_NUMITEMS, 0, 0, 0, nftCostData);
        }
        // Otherwise, the current base price is greater than or equal to the total amount that the base price changes
        // Thus we don't need to calculate the maximum number of items until we reach zero base price, so we don't modify numItems

        // The new base price is just the change between base price and the total price change
        newBasePrice = basePrice - uint128(totalPriceDecrease);

        // If we sell n items, then the total sale amount is:
        // (base price) + (base price - 1*delta) + (base price - 2*delta) + ... + (base price - (n-1)*delta)
        // This is equal to n*(base price) - (delta)*(n*(n-1))/2
        outputValue = numItems * basePrice - (numItems * (numItems - 1) * delta) / 2;

        uint256 totalFees;
        (totalFees, nftCostData) = _calculateUniformNftCostData(outputValue, numItems, fee_);

        outputValue -= totalFees;

        // Keep delta the same
        newDelta = delta;

        // If we reached here, no math errors
        error = CurveErrorCode.OK;
    }

    ///@inheritdoc IDittoPool
    function getBuyNftQuote(uint256 numNfts_, bytes calldata swapData_)
        external
        view
        override(IDittoPool, DittoPoolTrade)
        returns (
            CurveErrorCode error,
            uint256 newBasePrice,
            uint256 newDelta,
            uint256 inputAmount,
            NftCostData[] memory nftCostData
        )
    {
        (error, newBasePrice, newDelta, inputAmount, nftCostData) = _getBuyInfo(
            _basePrice,
            _delta,
            numNfts_,
            swapData_,
            Fee({lp: _feeLp, admin: _feeAdmin, protocol: _dittoPoolFactory.getProtocolFee()})
        );
    }

    ///@inheritdoc IDittoPool
    function getSellNftQuote(uint256 numNfts_, bytes calldata swapData_)
        external
        view
        override(IDittoPool, DittoPoolTrade)
        returns (
            CurveErrorCode error,
            uint256 newBasePrice,
            uint256 newDelta,
            uint256 outputAmount,
            NftCostData[] memory nftCostData
        )
    {
        (error, newBasePrice, newDelta, outputAmount, nftCostData) =
        _getSellInfo(
            _basePrice,
            _delta,
            numNfts_,
            swapData_,
            Fee({lp: _feeLp, admin: _feeAdmin, protocol: _dittoPoolFactory.getProtocolFee()})
        );
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

/**
 * @title Fee
 * @notice Struct to hold the fee amounts for LP, admin and protocol. Is used in the protocol to 
 *   pass the fee percentages and the total fee amount depending on the context.
 */
struct Fee {
    uint256 lp;
    uint256 admin;
    uint256 protocol;
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.19;

import { Fee } from "./Fee.sol";

struct NftCostData {
    bool specificNftId;
    uint256 nftId;
    uint256 price;
    Fee fee;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

import { Fee } from "../struct/Fee.sol";
import { SwapNftsForTokensArgs, SwapTokensForNftsArgs } from "../struct/SwapArgs.sol";
import { LpNft } from "../pool/lpNft/LpNft.sol";
import { PoolTemplate } from "../struct/FactoryTemplates.sol";
import { LpIdToTokenBalance } from "../struct/LpIdToTokenBalance.sol";
import { NftCostData } from "../struct/NftCostData.sol";
import { IPermitter } from "../interface/IPermitter.sol";

import { IERC721 } from "../../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import { CurveErrorCode } from "../utils/CurveErrorCode.sol";

import { IOwnerTwoStep } from "./IOwnerTwoStep.sol";

interface IDittoPool is IOwnerTwoStep {
    // ***************************************************************
    // * =============== ADMINISTRATIVE FUNCTIONS ================== *
    // ***************************************************************

    /**
     * @notice For use in tokenURI function metadata
     * @return curve type of curve
     */
    function bondingCurve() external pure returns (string memory curve);

    /**
     * @notice Used by the Contract Factory to set the initial state & parameters of the pool.
     * @dev Necessarily separate from constructor due to [ERC-1167](https://eips.ethereum.org/EIPS/eip-1167) factory clone paradigm.
     * @param params_ A struct that contains various initialization parameters for the pool. See `PoolTemplate.sol` for details.
     * @param template_ which address was used to clone business logic for this pool.
     * @param lpNft_ The Liquidity Provider Positions NFT contract that tokenizes liquidity provisions in the protocol
     * @param permitter_ Contract to authorize which tokenIds from the underlying nft collection are allowed to be traded in this pool.
     * @dev Set permitter to address(0) to allow any tokenIds from the underlying NFT collection.
     */
    function initPool(
        PoolTemplate calldata params_,
        address template_,
        LpNft lpNft_,
        IPermitter permitter_
    ) external;

    /**
     * @notice Admin function to change the base price charged to buy an NFT from the pair. Each bonding curve uses this differently.
     * @param newBasePrice_ The updated base price
     */
    function changeBasePrice(uint128 newBasePrice_) external;

    /**
     * @notice Admin function to change the delta parameter associated with the bonding curve. Each bonding curve uses this differently. 
     * @param newDelta_ The updated delta
     */
    function changeDelta(uint128 newDelta_) external;

    /**
     * @notice Admin function to change the pool lp fee, set by owner, paid to LPers only when they are the counterparty in a trade
     * @param newFeeLp_ New fee, in wei / 1e18, charged by the pool for trades with it (i.e. 1% = 0.01e18)
     */
    function changeLpFee(uint96 newFeeLp_) external;

    /**
     * @notice Change the pool admin fee, set by owner, paid to an address of the owner's choosing
     * @param newFeeAdmin_ New fee, in wei / 1e18, charged by the pool for trades with it (i.e. 1% = 0.01e18)
     */
    function changeAdminFee(uint96 newFeeAdmin_) external;

    /**
     * @notice Change who the pool admin fee for this pool is sent to.
     * @param newAdminFeeRecipient_ New address to send admin fees to
     */
    function changeAdminFeeRecipient(address newAdminFeeRecipient_) external;

    // ***************************************************************
    // * ================== LIQUIDITY FUNCTIONS ==================== *
    // ***************************************************************
    /**
     * @notice Function for liquidity providers to create new Liquidity Positions within the pool by depositing liquidity.
     * @dev Provides the liquidity provider with a new liquidity position tracking NFT every time. 
     * @dev This function assumes that msg.sender is the owner of the NFTs and Tokens.
     * @dev This function expects that this contract has permission to move NFTs and tokens to itself from the owner.
     * @dev The **lpRecipient_** parameter to this function is intended to allow creating positions on behalf of
     * another party. msg.sender can send nfts and tokens to the pool and then have the pool create the liquidity position
     * for someone who is not msg.sender. The `DittoPoolFactory` uses this feature to create a new DittoPool and deposit
     * liquidity into it in one step. NFTs flow from user -> factory -> pool and then lpRecipient_ is set to the user.
     * @dev `lpRecipient_` can steal liquidity deposited by msg.sender if lpRecipient_ is not set to msg.sender.
     * @param lpRecipient_ The address that will receive the LP position ownership NFT.
     * @param nftIdList_ The list of NFT tokenIds msg.sender wishes to deposit into the pool.
     * @param tokenDepositAmount_ The amount of ERC20 tokens msg.sender wishes to deposit into the pool.
     * @param permitterData_ Data to check that the NFT Token IDs are permitted to deposited into this pool if a permitter is set.
     * @return lpId The tokenId of the LP position NFT that was minted as a result of this liquidity deposit.
     */
    function createLiquidity(
        address lpRecipient_,
        uint256[] calldata nftIdList_,
        uint256 tokenDepositAmount_,
        bytes calldata permitterData_,
        bytes calldata referrer_
    ) external returns (uint256 lpId);

    /**
     * @notice Function for market makers / liquidity providers to deposit NFTs and ERC20s into existing LP Positions.
     * @dev Anybody may add liquidity to existing LP Positions, regardless of whether they own the position or not.
     * @dev This function expects that this contract has permission to move NFTs and tokens to itself from the msg.sender.
     * @param lpId_ TokenId of existing LP position to add liquidity to. Does not have to be owned by msg.sender!
     * @param nftIdList_ The list of NFT tokenIds msg.sender wishes to deposit into the pool.
     * @param tokenDepositAmount_ The amount of ERC20 tokens msg.sender wishes to deposit into the pool.
     * @param permitterData_ Data to check that the NFT Token IDs are permitted to deposited into this pool if a permitter is set.
     */
    function addLiquidity(
        uint256 lpId_,
        uint256[] calldata nftIdList_,
        uint256 tokenDepositAmount_,
        bytes calldata permitterData_,
        bytes calldata referrer_
    ) external;

    /**
     * @notice Function for liquidity providers to withdraw NFTs and ERC20 tokens from their LP positions.
     * @dev Can be called to change an existing liquidity position, or remove an LP position by withdrawing all liquidity.
     * @dev May be called by an authorized party (approved on the LP NFT) to withdraw liquidity on behalf of the LP Position owner.
     * @param withdrawalAddress_ the address that will receive the ERC20 tokens and NFTs withdrawn from the pool.
     * @param lpId_ LP Position TokenID that liquidity is being removed from. Does not have to be owned by msg.sender if the msg.sender is authorized.
     * @param nftIdList_ The list of NFT tokenIds msg.sender wishes to withdraw from the pool.
     * @param tokenWithdrawAmount_ The amount of ERC20 tokens the msg.sender wishes to withdraw from the pool.
     */
    function pullLiquidity(
        address withdrawalAddress_,
        uint256 lpId_,
        uint256[] calldata nftIdList_,
        uint256 tokenWithdrawAmount_
    ) external;

    // ***************************************************************
    // * =================== TRADE FUNCTIONS ======================= *
    // ***************************************************************

    /**
     * @notice Trade ERC20s for a specific list of NFT token ids.
     * @dev To compute the amount of token to send, call bondingCurve.getBuyInfo
     * This swap is meant for users who want specific IDs. 
     * 
     * @param args_ The arguments for the swap. See SwapArgs.sol for parameters
     * @return inputAmount The actual amount of tokens spent to purchase the NFTs.
     */
    function swapTokensForNfts(
        SwapTokensForNftsArgs calldata args_
    ) external returns (uint256 inputAmount);

    /**
     * @notice Trade a list of allowed nft ids for ERC20s.
     * @dev To compute the amount of token to that will be received, call bondingCurve.getSellInfo.
     * @dev Key difference with sudoswap here:
     * In sudoswap, each market maker has a separate smart contract with their liquidity.
     * To sell to a market maker, you just check if their specific `LSSVMPair` contract has enough money.
     * In DittoSwap, we share different market makers' liquidity in the same pool contract.
     * So this function has an additional parameter `lpIds` forcing the buyer to check
     * off-chain which market maker's LP position that they want to trade with, for each specific NFT
     * that they are selling into the pool. The lpIds array should correspond with the nftIds
     * array in the same order & indexes. e.g. to sell NFT with tokenId 1337 to the market maker who's
     * LP position has id 42, the buyer would call this function with
     * nftIds = [1337] and lpIds = [42].
     *
     * @param args_ The arguments for the swap. See SwapArgs.sol for parameters
     * @return outputAmount The amount of token received
     */
    function swapNftsForTokens(
        SwapNftsForTokensArgs calldata args_
    ) external returns (uint256 outputAmount);

    /**
     * @notice Read-only function used to query the bonding curve for buy pricing info.
     * @param numNfts The number of NFTs to buy out of the pair
     * @param swapData_ Extra data to pass to the curve
     * @return error any errors that would be throw if trying to buy that many NFTs
     * @return newBasePrice the new base price after the trade
     * @return newDelta the new delta after the trade
     * @return inputAmount the amount of token to send to the pool to purchase that many NFTs
     * @return nftCostData the cost data for each NFT purchased
     */
    function getBuyNftQuote(uint256 numNfts, bytes calldata swapData_)
        external
        view
        returns (
            CurveErrorCode error,
            uint256 newBasePrice,
            uint256 newDelta,
            uint256 inputAmount,
            NftCostData[] memory nftCostData
        );

    /**
     * @notice Read-only function used to query the bonding curve for sell pricing info
     * @param numNfts The number of NFTs to sell into the pair
     * @param swapData_ Extra data to pass to the curve
     * @return error any errors that would be throw if trying to sell that many NFTs
     * @return newBasePrice the new base price after the trade
     * @return newDelta the new delta after the trade
     * @return outputAmount the amount of tokens the pool will send out for selling that many NFTs
     * @return nftCostData the cost data for each NFT sold
     */
    function getSellNftQuote(uint256 numNfts, bytes calldata swapData_)
        external
        view
        returns (
            CurveErrorCode error,
            uint256 newBasePrice,
            uint256 newDelta,
            uint256 outputAmount,
            NftCostData[] memory nftCostData
        );

    // ***************************************************************
    // * ===================== VIEW FUNCTIONS ====================== *
    // ***************************************************************

    /**
     * @notice returns the status of whether this contract has been initialized
     * @dev see [ERC-1167](https://eips.ethereum.org/EIPS/eip-1167) factory clone paradigm
     * and also `DittoPoolFactory.sol`
     *
     * @return initialized whether the contract has been initialized
     */
    function initialized() external view returns (bool);

    /**
     * @notice returns which DittoPool Template this pool was created with.
     * @dev see [ERC-1167](https://eips.ethereum.org/EIPS/eip-1167) factory clone paradigm
     * @return template the address of the DittoPool template used to create this pool.
     */
    function template() external view returns (address);

    /**
     * @notice Function to determine if a given DittoPool can support muliple LP providers or not.
     * @return isPrivatePool_ boolean value indicating if the pool is private or not
     */
    function isPrivatePool() external view returns (bool isPrivatePool_);

    /**
     * @notice Returns the cumulative fee associated with trading with this pool as a 1e18 based percentage.
     * @return fee_ the total fee(s) associated with this pool, for display purposes.
     */
    function fee() external view returns (uint256 fee_);

    /**
     * @notice Returns the protocol fee associated with trading with this pool as a 1e18 based percentage.
     * @return feeProtocol_ the protocol fee associated with trading with this pool
     */
    function protocolFee() external view returns (uint256 feeProtocol_);

    /**
     * @notice Returns the admin fee given to the pool admin as a 1e18 based percentage.
     * @return adminFee_ the fee associated with trading with any pair of this pool
     */
    function adminFee() external view returns (uint96 adminFee_);

    /**
     * @notice Returns the fee given to liquidity providers for trading with this pool.
     * @return lpFee_ the fee associated with trading with a particular pair of this pool.
     */
    function lpFee() external view returns (uint96 lpFee_);

    /**
     * @notice Returns the delta parameter for the bonding curve associated this pool
     * Each bonding curve uses delta differently, but in general it is used as an input
     *   to determine the next price on the bonding curve.
     * @return delta_ The delta parameter for the bonding curve of this pool
     */
    function delta() external view returns (uint128 delta_);

    /**
     * @notice Returns the base price to sell the next NFT into this pool, base+delta to buy
     * Each bonding curve uses base price differently, but in general it is used as the current price of the pool.
     * @return basePrice_ this pool's current base price
     */
    function basePrice() external view returns (uint128 basePrice_);

    /**
     * @notice Returns the factory that created this pool.
     * @return dittoPoolFactory the ditto pool factory for the contract
     */
    function dittoPoolFactory() external view returns (address);

    /**
     * @notice Returns the address that recieves admin fees from trades with this pool
     * @return adminFeeRecipient The admin fee recipient of this pool
     */
    function adminFeeRecipient() external view returns (address);

    /**
     * @notice Returns the NFT collection that represents liquidity positions in this pool
     * @return lpNft The LP Position NFT collection for this pool
     */
    function getLpNft() external view returns (address);

    /**
     * @notice Returns the nft collection that this pool trades 
     * @return nft_ the address of the underlying nft collection contract
     */
    function nft() external view returns (IERC721 nft_);

    /**
     * @notice Returns the address of the ERC20 token that this pool is trading NFTs against.
     * @return token_ The address of the ERC20 token that this pool is trading NFTs against.
     */
    function token() external view returns (address token_);

    /**
     * @notice Returns the permitter contract that allows or denies specific NFT tokenIds to be traded in this pool
     * @dev if this address is zero, then all NFTs from the underlying collection are allowed to be traded in this pool
     * @return permitter the address of this pool's permitter contract, or zero if no permitter is set
     */
    function permitter() external view returns (IPermitter);

    /**
     * @notice Returns how many ERC20 tokens a liquidity provider has in the pool
     * @dev this function mimics mappings: an invalid lpId_ will return 0 rather than throwing for being invalid
     * @param lpId_ LP Position NFT token ID to query for
     * @return lpTokenBalance the amount of ERC20 tokens the liquidity provider has in the pool
     */
    function getTokenBalanceForLpId(uint256 lpId_) external view returns (uint256);

    /**
     * @notice Returns the full list of NFT tokenIds that are owned by a specific liquidity provider in this pool
     * @dev This function is not gas efficient and not-meant to be used on chain, only as a convenience for off-chain.
     * @dev worst-case is O(n) over the length of all the NFTs owned by the pool
     * @param lpId_ an LP position NFT token Id for a user providing liquidity to this pool
     * @return nftIds the list of NFT tokenIds in this pool that are owned by the specific liquidity provider
     */
    function getNftIdsForLpId(uint256 lpId_) external view returns (uint256[] memory nftIds);

    /**
     * @notice returns the number of NFTs owned by a specific liquidity provider in this pool
     * @param lpId_ a user providing liquidity to this pool for trading with
     * @return userNftCount the number of NFTs in this pool owned by the liquidity provider
     */
    function getNftCountForLpId(uint256 lpId_) external view returns (uint256);

    /**
     * @notice returns the number of NFTs and number of ERC20s owned by a specific liquidity provider in this pool
     * pretty much equivalent to the user's liquidity position in non-nft form.
     * @dev this function mimics mappings: an invalid lpId_ will return (0,0) rather than throwing for being invalid
     * @param lpId_ a user providing liquidity to this pool for trading with
     * @return tokenBalance the amount of ERC20 tokens the liquidity provider has in the pool
     * @return nftBalance the number of NFTs in this pool owned by the liquidity provider
     */
    function getTotalBalanceForLpId(uint256 lpId_)
        external
        view
        returns (uint256 tokenBalance, uint256 nftBalance);

    /**
     * @notice returns the Lp Position NFT token Id that owns a specific NFT token Id in this pool
     * @dev this function mimics mappings: an invalid NFT token Id will return 0 rather than throwing for being invalid
     * @param nftId_ an NFT token Id that is owned by a liquidity provider in this pool
     * @return lpId the Lp Position NFT token Id that owns the NFT token Id
     */
    function getLpIdForNftId(uint256 nftId_) external view returns (uint256);

    /**
     * @notice returns the full list of all NFT tokenIds that are owned by this pool
     * @dev does not have to match what the underlying NFT contract balanceOf(dittoPool)
     * thinks is owned by this pool: this is only valid liquidity tradeable in this pool
     * NFTs can be lost by unsafe transferring them to a dittoPool
     * also this function is O(n) gas efficient, only really meant to be used off-chain
     * @return nftIds the list of all NFT Token Ids in this pool, across all liquidity positions
     */
    function getAllPoolHeldNftIds() external view returns (uint256[] memory);

    /**
     * @dev Returns the number of NFTs owned by the pool
     * @return nftBalance_ The number of NFTs owned by the pool
     */
    function getPoolTotalNftBalance() external view returns (uint256);

    /**
     * @notice returns the full list of all LP Position NFT tokenIds that represent liquidity in this pool
     * @return lpIds the list of all LP Position NFT Token Ids corresponding to liquidity in this pool
     */
    function getAllPoolLpIds() external view returns (uint256[] memory);

    /**
     * @notice returns the full amount of all ERC20 tokens that the pool thinks it owns
     * @dev may not match the underlying ERC20 contract balanceOf() because of unsafe transfers
     * this is only accounting for valid liquidity tradeable in the pool
     * @dev this function is not gas efficient and almost certainly should never actually be used on chain
     * @return totalPoolTokenBalance the amount of ERC20 tokens the pool thinks it owns
     */
    function getPoolTotalTokenBalance() external view returns (uint256);

    /**
     * @notice returns the enumerated list of all token balances for all LP positions in this pool
     * @dev this function is not gas efficient and almost certainly should never actually be used on chain
     * @return balances the list of all LP Position NFT Token Ids and the amount of ERC20 tokens they are apportioned in the pool
     */
    function getAllLpIdTokenBalances()
        external
        view
        returns (LpIdToTokenBalance[] memory balances);

    /**
     * @notice function called on SafeTransferFrom of NFTs to this contract
     * @dev see [ERC-721](https://eips.ethereum.org/EIPS/eip-721) for details
     */
    function onERC721Received(address, address, uint256, bytes memory) external returns (bytes4);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

import { IDittoPool } from "../interface/IDittoPool.sol";

import { DittoPoolMain } from "./DittoPoolMain.sol";
import { DittoPoolMarketMake } from "./DittoPoolMarketMake.sol";
import { DittoPoolTrade } from "./DittoPoolTrade.sol";

/**
 * @title DittoPool
 * @notice DittoPool AMM shared liquidity trading pools. See DittoPoolMain, MarketMake and Trade for implementation.
 */
abstract contract DittoPool is IDittoPool, DittoPoolMain, DittoPoolMarketMake, DittoPoolTrade { }

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

enum CurveErrorCode {
    OK, // No error
    INVALID_NUMITEMS, // The numItem value is 0 or too large
    BASE_PRICE_OVERFLOW, // The updated base price doesn't fit into 128 bits
    SELL_NOT_SUPPORTED, // The pool doesn't support sell
    BUY_NOT_SUPPORTED, // The pool doesn't support buy
    MISSING_SWAP_DATA, // No swap data provided for a pool that requires it
    NOOP // No operation was performed
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

import { CurveErrorCode } from "../utils/CurveErrorCode.sol";

import { EnumerableSet } from
    "../../lib/openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";
import { EnumerableMap } from
    "../../lib/openzeppelin-contracts/contracts/utils/structs/EnumerableMap.sol";
import { SafeTransferLib } from "../../lib/solmate/src/utils/SafeTransferLib.sol";
import { ERC20 } from "../../lib/solmate/src/tokens/ERC20.sol";

import { Fee } from "../struct/Fee.sol";
import { SwapNftsForTokensArgs, SwapTokensForNftsArgs } from "../struct/SwapArgs.sol";
import { NftCostData } from "../struct/NftCostData.sol";
import { IDittoPool } from "../interface/IDittoPool.sol";
import { IDittoRouter } from "../interface/IDittoRouter.sol";
import { DittoPoolMain } from "./DittoPoolMain.sol";


/**
 * @title DittoPool
 * @notice Parent contract defines common functions for DittoPool AMM shared liquidity trading pools.
 */
abstract contract DittoPoolTrade is DittoPoolMain {
    using SafeTransferLib for ERC20;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToUintMap;

    // ***************************************************************
    // * ========================= EVENTS ========================== *
    // ***************************************************************

    event DittoPoolTradeSwappedTokensForNfts(
        address caller,
        SwapTokensForNftsArgs args,
        uint128 newBasePrice,
        uint128 newDelta
    );
    event DittoPoolTradeSwappedTokensForNft(
        uint256 sellerLpId,
        uint256 nftId,
        uint256 price,
        Fee fee
    );

    event DittoPoolTradeSwappedNftsForTokens(
        address caller,
        SwapNftsForTokensArgs args,
        uint128 newBasePrice,
        uint128 newDelta
    );
    event DittoPoolTradeSwappedNftForTokens(
        uint256 buyerLpId,
        uint256 nftId,
        uint256 price,
        Fee fee
    );

    // ***************************************************************
    // * ========================= ERRORS ========================== *
    // ***************************************************************

    error DittoPoolTradeBondingCurveError(CurveErrorCode error);
    error DittoPoolTradeNoNftsProvided();
    error DittoPoolTradeNftAndLpIdsMustBeSameLength();
    error DittoPoolTradeInvalidTokenRecipient();
    error DittoPoolTradeInsufficientBalanceToBuyNft();
    error DittoPoolTradeInsufficientBalanceToPayFees();
    error DittoPoolTradeInTooManyTokens();
    error DittoPoolTradeOutTooFewTokens();
    error DittoPoolTradeNftNotOwnedByPool(uint256 nftId);
    error DittoPoolTradeInvalidTokenSender();
    error DittoPoolTradeNftIdDoesNotMatchSwapData();
    error DittoPoolTradeNftAndCostDataLengthMismatch();

    // ***************************************************************
    // * =========== FUNCTIONS TO TRADE WITH THE POOL ============== *
    // ***************************************************************

    ///@inheritdoc IDittoPool
    function swapTokensForNfts(
        SwapTokensForNftsArgs calldata args_
    ) external nonReentrant returns (uint256 inputAmount) {
        uint256 countNfts = args_.nftIds.length;

        // STEP 1: Input validation
        if (countNfts == 0) {
            revert DittoPoolTradeNoNftsProvided();
        }

        // STEP 2: Get price information from bonding curve
        NftCostData[] memory nftCostData;
        uint128 newBasePrice;
        uint128 newDelta;
        (inputAmount, nftCostData, newBasePrice, newDelta) =
            _calculateBuyInfoAndUpdatePoolParams(countNfts, args_.swapData, args_.maxExpectedTokenInput);
        
        _checkNftIdsMatch(args_.nftIds, nftCostData);
        
        // STEP 3: Take in tokens for sellers (doesn't include fees)
        if (_dittoPoolFactory.isWhitelistedRouter(msg.sender)) {
            IDittoRouter(msg.sender).poolTransferErc20From(
                _token, args_.tokenSender, address(this), inputAmount
            );
        } else {
            if (args_.tokenSender != msg.sender){
                revert DittoPoolTradeInvalidTokenSender();
            }
            _token.transferFrom(args_.tokenSender, address(this), inputAmount);
        }

        // STEP 4: Transfer nfts to buyer and adjust nft balance of seller accounts
        uint256[] memory sellersLpIds = _sendNftsToBuyer(args_.nftRecipient, args_.nftIds);

        // STEP 5: Increase the token balance of the positions selling the nfts
        _increaseTokenBalanceOfSellers(nftCostData, sellersLpIds, args_.nftIds);

        // STEP 6: Pay protocol and admin fees
        _payProtocolAndAdminFees(nftCostData);

        emit DittoPoolTradeSwappedTokensForNfts(msg.sender, args_, newBasePrice, newDelta);
    }

    ///@inheritdoc IDittoPool
    function swapNftsForTokens(
        SwapNftsForTokensArgs calldata args_
    ) external nonReentrant returns (uint256 outputAmount) {
        uint256 countNfts = args_.nftIds.length;
        bool isWhitelistedRouter = _dittoPoolFactory.isWhitelistedRouter(msg.sender);

        // STEP 1: Input validation
        if (countNfts == 0) {
            revert DittoPoolTradeNoNftsProvided();
        }
        if (countNfts != args_.lpIds.length) {
            revert DittoPoolTradeNftAndLpIdsMustBeSameLength();
        }
        if (args_.tokenRecipient == address(0)) {
            revert DittoPoolTradeInvalidTokenRecipient();
        }
        if(!isWhitelistedRouter && args_.nftSender != msg.sender){
            revert DittoPoolTradeInvalidTokenSender();
        }

        _checkPermittedTokens(args_.nftIds, args_.permitterData);

        // STEP 2: Get price information from bonding curve
        NftCostData[] memory nftCostData;
        uint128 newBasePrice;
        uint128 newDelta;
        (outputAmount, nftCostData, newBasePrice, newDelta) =
            _calculateSellInfoAndUpdatePoolParams(countNfts, args_.swapData, args_.minExpectedTokenOutput);

        _checkNftIdsMatch(args_.nftIds, nftCostData);

        // STEP 3: Charge the buyers for the Nfts by reducing their token balance
        _decreaseTokenBalanceOfBuyers(nftCostData, args_.nftIds, args_.lpIds);

        // STEP 4: Transfer Nfts from seller to buyer accounts
        _takeSpecificNftsFromSeller(isWhitelistedRouter, args_.nftSender, args_.nftIds, args_.lpIds);

        // STEP 5: Transfer the token proceeds to the seller and pay fees
        _token.safeTransfer(args_.tokenRecipient, outputAmount);

        // STEP 6: Pay protocol and admin fees
        _payProtocolAndAdminFees(nftCostData);

        emit DittoPoolTradeSwappedNftsForTokens(msg.sender, args_, newBasePrice, newDelta);
    }

    ///@inheritdoc IDittoPool
    function getBuyNftQuote(uint256 numNfts_, bytes calldata swapData_)
        external
        view
        virtual
        returns (
            CurveErrorCode error,
            uint256 newBasePrice,
            uint256 newDelta,
            uint256 inputAmount,
            NftCostData[] memory nftCostData
        );

    ///@inheritdoc IDittoPool
    function getSellNftQuote(uint256 numNfts_, bytes calldata swapData_)
        external
        view
        virtual
        returns (
            CurveErrorCode error,
            uint256 newBasePrice,
            uint256 newDelta,
            uint256 outputAmount,
            NftCostData[] memory nftCostData
        );

    // ***************************************************************
    // * ============= INTERNAL HELPER FUNCTIONS =================== *
    // ***************************************************************
    /**
     * Check that the cost data matches the nft ids if that is important for the curve type 
     *   giving the cost data
     * @param nftIds_ The nft ids
     * @param nftCostData_ The cost data that may or may not require specific nft ids
     */
    function _checkNftIdsMatch(
        uint256[] memory nftIds_, 
        NftCostData[] memory nftCostData_
    ) internal pure {
        uint256 countNfts = nftIds_.length;
        if (countNfts != nftCostData_.length) {
            revert DittoPoolTradeNftAndCostDataLengthMismatch();
        }
        for (uint256 i = 0; i < countNfts;) {
            if (nftCostData_[i].specificNftId && nftIds_[i] != nftCostData_[i].nftId) {
                revert DittoPoolTradeNftIdDoesNotMatchSwapData();
            }
            unchecked {
                ++i;
            }
        }
    }

    /**
     * Pays protocol and admin fees to the appropriate recipients
     * 
     * @param nftCostData_ the cost data including the fees
     */
    function _payProtocolAndAdminFees(NftCostData[] memory nftCostData_) internal {
        uint256 totalProtocolFee;
        uint256 totalAdminFee;
        uint256 numItems = nftCostData_.length;

        for (uint256 i = 0; i < numItems;) {
            totalProtocolFee += nftCostData_[i].fee.protocol;
            totalAdminFee += nftCostData_[i].fee.admin;
            unchecked {
                ++i;
            }
        }


        ERC20 token = _token;
        uint256 balance = token.balanceOf(address(this));
        if (balance < totalProtocolFee + totalAdminFee) {
            revert DittoPoolTradeInsufficientBalanceToPayFees();
        }
        token.safeTransfer(_dittoPoolFactory.protocolFeeRecipient(), totalProtocolFee);
        token.safeTransfer(_adminFeeRecipient, totalAdminFee);
    }

    /**
     * @notice In purchases of NFTs leaving the pool, increase token balance accounting of the NFT seller in the pool.
     * @param nftCostData array of NFT buy cost data
     * @param sellersLpIds_ list of addresses of NFT selling counterparties (LP providers within the pool) in this trade
     */
    function _increaseTokenBalanceOfSellers(
        NftCostData[] memory nftCostData,
        uint256[] memory sellersLpIds_,
        uint256[] memory nftIds_
    ) private {
        uint256 sellerLpId;
        uint256 sellerCurrentBalance;
        uint256 countSellerPositions = sellersLpIds_.length;

        for (uint256 i = 0; i < countSellerPositions;) {
            sellerLpId = sellersLpIds_[i];
            (, sellerCurrentBalance) = _lpIdToTokenBalance.tryGet(sellerLpId);
            _lpIdToTokenBalance.set(
                sellerLpId, 
                sellerCurrentBalance + nftCostData[i].price + nftCostData[i].fee.lp
            );

            emit DittoPoolTradeSwappedTokensForNft(
                sellerLpId,
                nftIds_[i],
                nftCostData[i].price,
                nftCostData[i].fee
            );

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice In sales of NFTs into the pool for tokens, decrease the NFT seller's tokens balance accounting in the pool.
     * @dev this function throws if the liquidity provider does not have enough tokens to buy the NFTs
     * @param nftCostData_ array of NFT sell cost data
     * @param buyerLpIds_ the NFT buying counterparties, LP providers within the pool's Lp Position Token Ids
     */
    function _decreaseTokenBalanceOfBuyers(
        NftCostData[] memory nftCostData_,
        uint256[] memory nftIds_,
        uint256[] memory buyerLpIds_
    ) private {
        uint256 buyerLpId;
        uint256 buyerCurrentBalance;
        uint256 countBuyerPositions = buyerLpIds_.length;
        uint256 sellPriceIgnoreLpFee;
        for (uint256 i = 0; i < countBuyerPositions;) {
            buyerLpId = buyerLpIds_[i];
            sellPriceIgnoreLpFee = nftCostData_[i].price - nftCostData_[i].fee.lp;
            buyerCurrentBalance = _lpIdToTokenBalance.get(buyerLpId);
            if (buyerCurrentBalance < sellPriceIgnoreLpFee) {
                revert DittoPoolTradeInsufficientBalanceToBuyNft();
            }

            emit DittoPoolTradeSwappedNftForTokens(
                buyerLpId,
                nftIds_[i],
                nftCostData_[i].price,
                nftCostData_[i].fee
            );

            unchecked {
                _lpIdToTokenBalance.set(buyerLpId, buyerCurrentBalance - sellPriceIgnoreLpFee);
                ++i;
            }
        }
    }

    /**
     * @notice Updates LP position NFT metadata on trades, as LP's LP information changes due to the trade
     * @dev see [EIP-4906](https://eips.ethereum.org/EIPS/eip-4906) EIP-721 Metadata Update Extension
     * @param lpId_ LP position NFT token id whose metadata needs updating
     */
    function _updateLpNftMetadataOnTrade(uint256 lpId_) internal {
        _lpNft.emitMetadataUpdate(lpId_);
    }

    /**
     * @notice In a purchase of NFTs leaving the pool (`swapTokenForNfts`), sends NFTs to buyer, and
     * updates the pool's internal accounting of NFTs in the pool
     * @param nftRecipient_ the address to send the NFTs to
     * @param nftIds_ the list of specific NFT token Ids being purchased out of the pool in this transaction
     * @return sellersLpIds position ids of the lp positions selling within the pool
     */
    function _sendNftsToBuyer(
        address nftRecipient_,
        uint256[] calldata nftIds_
    ) internal returns (uint256[] memory sellersLpIds) {
        uint256 countNftIds = nftIds_.length;

        uint256 nftId;
        sellersLpIds = new uint256[](countNftIds);

        for (uint256 i = 0; i < countNftIds;) {
            nftId = nftIds_[i];

            if (_poolOwnedNftIds.contains(nftId) == false) {
                revert DittoPoolTradeNftNotOwnedByPool(nftId);
            }

            _nft.safeTransferFrom(address(this), nftRecipient_, nftId);

            _poolOwnedNftIds.remove(nftId);
            uint256 prevOwnerLpId = _nftIdToLpId[nftId];
            delete _nftIdToLpId[nftId];
            _lpIdToNftBalance[prevOwnerLpId]--;

            _updateLpNftMetadataOnTrade(prevOwnerLpId);
            sellersLpIds[i] = prevOwnerLpId;

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice In a sale of NFTs into the pool, transfers the NFTs from the seller to the pool, and
     * updates the pool's internal accounting of NFTs in the pool
     * @dev Sends NFTs to recipients
     * @dev This adds the ids to to the global id set and increments the nft count for each buyer.
     * @param from_ the address to take the NFTs from, only used if msg.sender is an approved IDittoRouter
     * @param nftIds_ the list of specific NFT token Ids being purchased into the pool in this transaction
     * @param buyerLpIds_ the list of addresses of NFT buying counterparties (LP providers within the pool) buying NFTs in this trade
     */
    function _takeSpecificNftsFromSeller(
        bool isWhitelistedRouter_,
        address from_,
        uint256[] calldata nftIds_,
        uint256[] memory buyerLpIds_
    ) internal {
        uint256 countNftIds = nftIds_.length;
        uint256 nftId;
        for (uint256 i = 0; i < countNftIds;) {
            nftId = nftIds_[i];
            if (isWhitelistedRouter_) {
                IDittoRouter(msg.sender).poolTransferNftFrom(_nft, from_, address(this), nftId);
            } else {
                _nft.transferFrom(msg.sender, address(this), nftId);
            }
            _poolOwnedNftIds.add(nftId);
            _nftIdToLpId[nftId] = buyerLpIds_[i];
            _lpIdToNftBalance[buyerLpIds_[i]]++;

            _updateLpNftMetadataOnTrade(buyerLpIds_[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice In purchase of NFTs out of the pool, call bonding curve to find out how much erc20 is required, and
     * update new prices for the next NFT in the pool after this trade completes
     * @param numNFTs_ the number of NFTs being purchased
     * @param swapData_ extra data to be passed to the curve
     * @param maxExpectedTokenInput_ the maximum amount of tokens the user is willing to pay for the NFTs
     * @return inputAmount the amount of tokens the user needs to send to pay for the NFTsgetProtocolFee
     * @return nftCostData the data returned from the bonding curve
     */
    function _calculateBuyInfoAndUpdatePoolParams(
        uint256 numNFTs_,
        bytes calldata swapData_,
        uint256 maxExpectedTokenInput_
    ) internal returns (
        uint256 inputAmount, 
        NftCostData[] memory nftCostData,
        uint128 newBasePrice,
        uint128 newDelta
    ) {
        CurveErrorCode error;
        // Save on 2 SLOADs by caching
        uint128 currentBasePrice = _basePrice;
        uint128 currentDelta = _delta;
        (error, newBasePrice, newDelta, inputAmount, nftCostData) = _getBuyInfo(
            currentBasePrice,
            currentDelta,
            numNFTs_,
            swapData_,
            Fee({lp: _feeLp, admin: _feeAdmin, protocol: _dittoPoolFactory.getProtocolFee()})
        );

        // Revert if bonding curve had an error
        if (error != CurveErrorCode.OK) {
            revert DittoPoolTradeBondingCurveError(error);
        }

        // Revert if input is more than expected
        if (inputAmount > maxExpectedTokenInput_) {
            revert DittoPoolTradeInTooManyTokens();
        }

        if (currentBasePrice != newBasePrice) {
            _changeBasePrice(newBasePrice);
        }

        if (currentDelta != newDelta) {
            _changeDelta(newDelta);
        }
    }

    /**
     * @notice In sales of NFTs into the pool, call bonding curve to find out
     *   how much money the seller will receive, and update new prices for the
     *   next NFT in the pool after this trade completes
     * @param numNFTs_ the number of NFTs being purchased
     * @param swapData_ extra data to be passed to the curve
     * @param minExpectedTokenOutput_ minimium amount of ERC20 msg.sender is willing
     *   to recieve for the sale of their NFTs
     * @return outputAmount the amount of tokens the msg.sender will recieve
     *   from the sale of their NFTs into the pool
     * @return nftCostData the data returned from the bonding curve
     */
    function _calculateSellInfoAndUpdatePoolParams(
        uint256 numNFTs_,
        bytes calldata swapData_,
        uint256 minExpectedTokenOutput_
    ) internal returns (
        uint256 outputAmount, 
        NftCostData[] memory nftCostData,
        uint128 newBasePrice,
        uint128 newDelta
    ) {
        // Save on 2 SLOADs by caching
        uint128 currentBasePrice = _basePrice;
        uint128 currentDelta = _delta;

        CurveErrorCode error;
        (error, newBasePrice, newDelta, outputAmount, nftCostData) =
            _getSellInfo(
                currentBasePrice,
                currentDelta,
                numNFTs_,
                swapData_,
                Fee({lp: _feeLp, admin: _feeAdmin, protocol: _dittoPoolFactory.getProtocolFee()})
            );

        // Revert if bonding curve had an error
        if (error != CurveErrorCode.OK) {
            revert DittoPoolTradeBondingCurveError(error);
        }

        // Revert if output is too little
        if (outputAmount < minExpectedTokenOutput_) {
            revert DittoPoolTradeOutTooFewTokens();
        }

        if (currentBasePrice != newBasePrice) {
            _changeBasePrice(newBasePrice);
        }

        if (currentDelta != newDelta) {
            _changeDelta(newDelta);
        }
    }

    /**
     * @notice Calculate the total fees and price per NFT for a uniform trade, meaning all nfts 
     *   involved in the trade have the same price
     * 
     * @param totalCost_ The total cost across all nfts in the trade
     * @param numItems_ The number of nfts in the trade. Assumed not to be zero
     * @param feeRates_ The fees to be applied to the trade
     * @return totalFees_ The total fees to be paid for the trade
     * @return nftCostData_ The price and fees per nft in the trade
     */
    function _calculateUniformNftCostData(
        uint256 totalCost_,
        uint256 numItems_,
        Fee memory feeRates_
    ) internal pure returns (
        uint256 totalFees_,
        NftCostData[] memory nftCostData_
    ) {
        uint256 pricePerNft = totalCost_ / numItems_;

        Fee memory calculatedFees = Fee({
            protocol: _mul(totalCost_, feeRates_.protocol),
            admin: _mul(totalCost_, feeRates_.admin),
            lp: _mul(totalCost_, feeRates_.lp)
        });

        totalFees_ = calculatedFees.protocol + calculatedFees.admin + calculatedFees.lp;

        Fee memory calculatedFeesPerNft = Fee({
            protocol: calculatedFees.protocol / numItems_,
            admin: calculatedFees.admin / numItems_,
            lp: calculatedFees.lp / numItems_
        });

        nftCostData_ = new NftCostData[](numItems_);

        for (uint256 i = 0; i < numItems_;) {
            nftCostData_[i].price = pricePerNft;
            nftCostData_[i].fee = calculatedFeesPerNft;

            unchecked {
                ++i;
            }
        }
    }

    // ***********************************************************************
    // * ============= INTERNAL HELPER FUNCTIONS (Curve) =================== *
    // ***********************************************************************

    /**
     * @notice Given the current state of the pair and the trade, computes how much the user
     * should pay to purchase an NFT from the pair, the new base price, and other values.
     * @param basePrice_ The current selling base price of the pair, in tokens
     * @param delta_ The delta parameter of the pair, what it means depends on the curve
     * @param numItems_ The number of NFTs the user is buying from the pair
     * @param fee_ The fee Lp, Admin, and Protocol fee multipliers
     * @return error Any math calculation errors, only Error.OK means the returned values are valid
     * @return newBasePrice The updated selling base price, in tokens
     * @return newDelta The updated delta, used to parameterize the bonding curve
     * @return inputValue The amount that the user should pay, in tokens
     * @return nftCostData The fees and buyPriceAndLpFeePerNft for each NFT being purchased
     */
    function _getBuyInfo(
        uint128 basePrice_,
        uint128 delta_,
        uint256 numItems_,
        bytes calldata swapData_,
        Fee memory fee_
    )
        internal
        virtual
        returns (
            CurveErrorCode error,
            uint128 newBasePrice,
            uint128 newDelta,
            uint256 inputValue,
            NftCostData[] memory nftCostData
        );

    /**
     * @notice Given the current state of the pair and the trade, computes how much the user
     * should receive when selling NFTs to the pair, the new base price, and other values.
     * @param basePrice_ The current selling base price of the pair, in tokens
     * @param delta_ The delta parameter of the pair, what it means depends on the curve
     * @param numItems_ The number of NFTs the user is selling to the pair
     * @param fee_ The Lp, Admin, and Protocol fees multipliers
     * @return error Any math calculation errors, only Error.OK means the returned values are valid
     * @return newBasePrice The updated selling base price, in tokens
     * @return newDelta The updated delta, used to parameterize the bonding curve
     * @return outputValue The amount that the user should receive, in tokens
     * @return nftCostData The fees and sellPricePerNftWithoutFees for each NFT being sold
     */
    function _getSellInfo(
        uint128 basePrice_,
        uint128 delta_,
        uint256 numItems_,
        bytes calldata swapData_,
        Fee memory fee_
    )
        internal
        virtual
        returns (
            CurveErrorCode error,
            uint128 newBasePrice,
            uint128 newDelta,
            uint256 outputValue,
            NftCostData[] memory nftCostData
        );
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.19;

/**
 * @param nftIds The list of IDs of the NFTs to purchase
 * @param maxExpectedTokenInput The maximum acceptable cost from the sender (in wei or base units of ERC20).
 *   If the actual amount is greater than this value, the transaction will be reverted.
 * @param tokenSender ERC20 sender. Only used if msg.sender is an approved IDittoRouter, else msg.sender is used.
 * @param nftRecipient Address to send the purchased NFTs to.
 */
struct SwapTokensForNftsArgs {
    uint256[] nftIds;
    uint256 maxExpectedTokenInput;
    address tokenSender;
    address nftRecipient;
    bytes swapData;
}

/**
 * @param nftIds The list of IDs of the NFTs to sell to the pair
 * @param lpIds The list of IDs of the LP positions sell the NFTs to
 * @param minExpectedTokenOutput The minimum acceptable token count received by the sender. 
 *   If the actual amount is less than this value, the transaction will be reverted.
 * @param nftSender NFT sender. Only used if msg.sender is an approved IDittoRouter, else msg.sender is used.
 * @param tokenRecipient The recipient of the ERC20 proceeds.
 * @param permitterData Data to profe that the NFT Token IDs are permitted to be sold to this pool if a permitter is set.
 * @param swapData Extra data to pass to the curve
 */
struct SwapNftsForTokensArgs {
    uint256[] nftIds;
    uint256[] lpIds;
    uint256 minExpectedTokenOutput;
    address nftSender;
    address tokenRecipient;
    bytes permitterData;
    bytes swapData;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

import { ILpNft } from "../../interface/ILpNft.sol";
import { IMetadataGenerator } from "../../interface/IMetadataGenerator.sol";
import { IDittoPool } from "../../interface/IDittoPool.sol";
import { IDittoPoolFactory } from "../../interface/IDittoPoolFactory.sol";
import { OwnerTwoStep } from "../../utils/OwnerTwoStep.sol";

import { IERC721 } from "../../../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import { ERC721 } from "../../../lib/solmate/src/tokens/ERC721.sol";

/**
 * @title LpNft
 * @notice LpNft is an ERC721 NFT collection that tokenizes market makers' liquidity positions in the Ditto protocol.
 */
contract LpNft is ILpNft, ERC721, OwnerTwoStep {
    IDittoPoolFactory internal immutable _dittoPoolFactory;

    ///@dev stores which pool each lpId corresponds to
    mapping(uint256 => IDittoPool) internal _lpIdToPool;

    /// @dev dittoPool address is the key of the mapping, underlying NFT address traded by that pool is the value
    mapping(address => IERC721) internal _approvedDittoPoolToNft;

    IMetadataGenerator internal _metadataGenerator;

    ///@dev NFTs are minted sequentially, starting at tokenId 1
    uint96 internal _nextId = 1;

    // ***************************************************************
    // * ========================= EVENTS ========================== *
    // ***************************************************************

    event LpNftAdminUpdatedMetadataGenerator(address metadataGenerator);

    // ***************************************************************
    // * ========================= ERRORS ========================== *
    // ***************************************************************
    error LpNftDittoFactoryOnly();
    error LpNftDittoPoolOnly();

    // ***************************************************************
    // * ==================== ADMIN FUNCTIONS ====================== *
    // ***************************************************************

    /**
     * @notice Constructor. Records the DittoPoolFactory address. Sets the owner of this contract. 
     *   Assigns the metadataGenerator address.
     */
    constructor(
        address initialOwner_,
        address metadataGenerator_
    ) ERC721("Ditto V1 LP Positions", "DITTO-V1-POS") {
        _transferOwnership(initialOwner_);
        _dittoPoolFactory = IDittoPoolFactory(msg.sender);
        _metadataGenerator = IMetadataGenerator(metadataGenerator_);
    }

    ///@inheritdoc ILpNft
    function setMetadataGenerator(IMetadataGenerator metadataGenerator_) external onlyDittoPoolFactory {
        _metadataGenerator = metadataGenerator_;

        emit LpNftAdminUpdatedMetadataGenerator(address(metadataGenerator_));
    }

    ///@inheritdoc ILpNft
    function setApprovedDittoPool(address dittoPool_, IERC721 nft_) external onlyDittoPoolFactory {
        _approvedDittoPoolToNft[dittoPool_] = nft_;
    }

    // ***************************************************************
    // * =============== PROTECTED POOL FUNCTIONS ================== *
    // ***************************************************************

    ///@inheritdoc ILpNft
    function mint(address to_) public onlyApprovedDittoPools returns (uint256 lpId) {
        lpId = _nextId;

        _lpIdToPool[lpId] = IDittoPool(msg.sender);

        _safeMint(to_, lpId);
        unchecked {
            ++_nextId;
        }
    }

    ///@inheritdoc ILpNft
    function burn(uint256 lpId_) external onlyApprovedDittoPools {
        delete _lpIdToPool[lpId_];

        _burn(lpId_);
    }

    ///@inheritdoc ILpNft
    function emitMetadataUpdate(uint256 lpId_) external onlyApprovedDittoPools {
        emit MetadataUpdate(lpId_);
    }

    ///@inheritdoc ILpNft
    function emitMetadataUpdateForAll() external onlyApprovedDittoPools {
        if (totalSupply > 0) {
            emit BatchMetadataUpdate(1, totalSupply);
        }
    }

    // ***************************************************************
    // * ==================== AUTH MODIFIERS ======================= *
    // ***************************************************************
    /**
     * @notice Modifier that restricts access to the DittoPoolFactory contract 
     *   that created this NFT collection.
     */
    modifier onlyDittoPoolFactory() {
        if (msg.sender != address(_dittoPoolFactory)) {
            revert LpNftDittoFactoryOnly();
        }
        _;
    }

    /**
     * @notice Modifier that restricts access to DittoPool contracts that have been 
     *   approved to mint and burn liquidity position NFTs by the DittoPoolFactory.
     */
    modifier onlyApprovedDittoPools() {
        if (address(_approvedDittoPoolToNft[msg.sender]) == address(0)) {
            revert LpNftDittoPoolOnly();
        }
        _;
    }

    // ***************************************************************
    // * ====================== VIEW FUNCTIONS ===================== *
    // ***************************************************************

    ///@inheritdoc ILpNft
    function isApproved(address spender_, uint256 lpId_) external view returns (bool) {
        address ownerOf = ownerOf[lpId_];
        return (
            spender_ == ownerOf || isApprovedForAll[ownerOf][spender_]
                || spender_ == getApproved[lpId_]
        );
    }

    ///@inheritdoc ILpNft
    function isApprovedDittoPool(address pool_) external view returns (bool) {
        return address(_approvedDittoPoolToNft[pool_]) != address(0);
    }

    ///@inheritdoc ILpNft
    function getPoolForLpId(uint256 lpId_) external view returns (IDittoPool) {
        return _lpIdToPool[lpId_];
    }

    ///@inheritdoc ILpNft
    function getPoolAndOwnerForLpId(uint256 lpId_)
        external
        view
        returns (IDittoPool pool, address owner)
    {
        pool = _lpIdToPool[lpId_];
        owner = ownerOf[lpId_];
    }

    ///@inheritdoc ILpNft
    function getNftForLpId(uint256 lpId_) external view returns (IERC721) {
        return _approvedDittoPoolToNft[address(_lpIdToPool[lpId_])];
    }

    ///@inheritdoc ILpNft
    function getLpValueToken(uint256 lpId_) public view returns (uint256) {
        return _lpIdToPool[lpId_].getTokenBalanceForLpId(lpId_);
    }

    ///@inheritdoc ILpNft
    function getAllHeldNftIds(uint256 lpId_) external view returns (uint256[] memory) {
        return _lpIdToPool[lpId_].getNftIdsForLpId(lpId_);
    }

    ///@inheritdoc ILpNft
    function getNumNftsHeld(uint256 lpId_) public view returns (uint256) {
        return _lpIdToPool[lpId_].getNftCountForLpId(lpId_);
    }

    ///@inheritdoc ILpNft
    function getLpValueNft(uint256 lpId_) public view returns (uint256) {
        return getNumNftsHeld(lpId_) * _lpIdToPool[lpId_].basePrice();
    }

    ///@inheritdoc ILpNft
    function getLpValue(uint256 lpId_) external view returns (uint256) {
        return getLpValueToken(lpId_) + getLpValueNft(lpId_);
    }

    ///@inheritdoc ILpNft
    function dittoPoolFactory() external view returns (IDittoPoolFactory) {
        return _dittoPoolFactory;
    }

    ///@inheritdoc ILpNft
    function nextId() external view returns (uint256) {
        return _nextId;
    }

    ///@inheritdoc ILpNft
    function metadataGenerator() external view returns (IMetadataGenerator) {
        return _metadataGenerator;
    }

    // ***************************************************************
    // * ================== ERC721 INTERFACE ======================= *
    // ***************************************************************

    /**
     *  @notice returns storefront-level metadata to be viewed on marketplaces.
     */
    function contractURI() external view returns (string memory) {
        return _metadataGenerator.payloadContractUri();
    }

    /**
     * @notice returns the metadata for a given token, to be viewed on marketplaces and off-chain
     * @dev see [EIP-721](https://eips.ethereum.org/EIPS/eip-721) EIP-721 Metadata Extension
     * @param lpId_ the tokenId of the NFT to get metadata for
     */
    function tokenURI(uint256 lpId_) public view override returns (string memory) {
        IDittoPool pool = IDittoPool(_lpIdToPool[lpId_]);
        uint256 tokenCount = getLpValueToken(lpId_);
        uint256 nftCount = getNumNftsHeld(lpId_);
        return _metadataGenerator.payloadTokenUri(lpId_, pool, tokenCount, nftCount);
    }

    /**
     * @notice Whether or not this contract supports the given interface. 
     *   See [EIP-165](https://eips.ethereum.org/EIPS/eip-165)
     */
    function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
        return interfaceId == 0x01ffc9a7 // ERC165 Interface ID for ERC165
            || interfaceId == 0x80ac58cd // ERC165 Interface ID for ERC721
            || interfaceId == 0x49064906 // ERC165 Interface ID for ERC4906
            || interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

/**
 * @notice A struct for creating a DittoSwap pool.
 */
struct PoolTemplate {
    bool isPrivatePool; // whether the pool is private or not
    uint256 templateIndex; // which DittoSwap template to use. Must be less than the number of available templates
    address token; // ERC20 token address
    address nft; // the address of the NFT collection that we are creating a pool for
    uint96 feeLp; // set by owner, paid to LPers only when they are the counterparty in a trade
    address owner; // owner creating the pool
    uint96 feeAdmin; // set by owner, paid to admin fee recipient
    uint128 delta; // the delta of the pool, see bonding curve documentation
    uint128 basePrice; // the base price of the pool, see bonding curve documentation
    uint256[] nftIdList; // the token IDs of NFTs to deposit into the pool
    uint256 initialTokenBalance; // the number of ERC20 tokens to transfer to the pool
    bytes templateInitData; // initial data to pass to the pool contract in its initializer
    bytes referrer; // the address of the referrer
}

/**
 * @notice A struct for containing Pool Manager template data.
 *  
 * @dev **templateIndex** Which DittoSwap template to use. If templateIndex is set to a value 
 *   larger than the number of templates, no pool manager is created
 * @dev **templateInitData** initial data to pass to the poolManager contract in its initializer.
 */
struct PoolManagerTemplate {
    uint256 templateIndex;
    bytes templateInitData;
}

/**
 * @notice A struct for containing Permitter template data.
 * @dev **templateIndex** Which DittoSwap template to use. If templateIndex is set to a value 
 *   larger than the number of templates, no permitter is created.
 * @dev **templateInitData** initial data to pass to the permitter contract in its initializer.
 * @dev **liquidityDepositPermissionData** Deposit data to pass in an all-in-one step to create a pool and deposit liquidity at the same time
 */
struct PermitterTemplate {
    uint256 templateIndex;
    bytes templateInitData;
    bytes liquidityDepositPermissionData;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

/**
 * @notice Tuple struct to encapsulate a LP Position NFT token Id and the amount of ERC20 tokens it owns in the pool
 * @dev **lpId** the LP Position NFT token Id of a liquidity provider
 * @dev **tokenBalance** the amount of ERC20 tokens the liquidity provider has in the pool attributed to them
 */
struct LpIdToTokenBalance {
    uint256 lpId;
    uint256 tokenBalance;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

/**
 * @title IPermitter
 * @notice Interface for the Permitter contracts. They are used to check whether a set of tokenIds
 *   are are allowed in a pool.
 */
interface IPermitter {
    /**
     * @notice Initializes the permitter contract with initial state.
     * @param data_ Any data necessary for initializing the permitter implementation.
     */
    function initialize(bytes memory data_) external;

    /**
     * @notice Returns whether or not the contract has been initialized.
     * @return initialized Whether or not the contract has been initialized.
     */
    function initialized() external view returns (bool);

    /**
     * @notice Checks that the provided permission data are valid for the provided tokenIds.
     * @param tokenIds_ The token ids to check.
     * @param permitterData_ data used by the permitter to perform checking.
     * @return permitted Whether or not the tokenIds are permitted to be added to the pool.
     */
    function checkPermitterData(
        uint256[] calldata tokenIds_,
        bytes memory permitterData_
    ) external view returns (bool permitted);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
pragma solidity 0.8.19;

/**
 * @title IOwnerTwoStep
 * @notice Interface for the OwnerTwoStep contract
 */
interface IOwnerTwoStep {

    // ***************************************************************
    // * =================== USER INTERFACE ======================== *
    // ***************************************************************

    /**
     * @notice Starts the ownership transfer of the contract to a new account. Replaces the 
     *   pending transfer if there is one. 
     * @dev Can only be called by the current owner.
     * @param newOwner_ The address of the new owner
     */
    function transferOwnership(address newOwner_) external;

    /**
     * @notice Completes the transfer process to a new owner.
     * @dev only callable by the pending owner that is accepting the new ownership.
     */
    function acceptOwnership() external;

    /**
     * @notice Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     */
    function renounceOwnership() external;

    // ***************************************************************
    // * =================== VIEW FUNCTIONS ======================== *
    // ***************************************************************

    /**
     * @notice Getter function to find out the current owner address
     * @return owner The current owner address
     */
    function owner() external view returns (address);

    /**
     * @notice Getter function to find out the pending owner address
     * @dev The pending address is 0 when there is no transfer of owner in progress
     * @return pendingOwner The pending owner address, if any
     */
    function pendingOwner() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

import { Math } from "../../lib/openzeppelin-contracts/contracts/utils/math/Math.sol";
import { OwnerTwoStep } from "../utils/OwnerTwoStep.sol";
import { LpNft } from "./lpNft/LpNft.sol";
import { IOwnerTwoStep } from "../interface/IOwnerTwoStep.sol";
import { IDittoPool } from "../interface/IDittoPool.sol";
import { IDittoPoolFactory } from "../interface/IDittoPoolFactory.sol";
import { IPermitter } from "../interface/IPermitter.sol";
import { PoolTemplate } from "../struct/FactoryTemplates.sol";
import { LpIdToTokenBalance } from "../struct/LpIdToTokenBalance.sol";
import { ERC20 } from "../../lib/solmate/src/tokens/ERC20.sol";
import { ReentrancyGuard } from
    "../../lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import { IERC721 } from "../../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import { EnumerableSet } from
    "../../lib/openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";
import { EnumerableMap } from
    "../../lib/openzeppelin-contracts/contracts/utils/structs/EnumerableMap.sol";

/**
 * @title DittoPool
 * @notice Contract that defines basic pool functionality used in DittoPoolMarketMake and DittoPoolTrade contracts
 * @notice Also defines admin functions for changing pool variables
 */
abstract contract DittoPoolMain is OwnerTwoStep, IDittoPool, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToUintMap;

    ///@dev Indication of whether or not this pool has more than one possible liquidity provider
    bool internal _isPrivatePool;
    ///@dev The ID of the LP Position that owns the pool if it is a private pool
    uint256 public _privatePoolOwnerLpId;

    ///@dev The full list of NFT ids owned by this pool that the pool is tracking. 
    EnumerableSet.UintSet internal _poolOwnedNftIds;

    ///@dev Stores which Lp Position owns which NFT in the pool
    mapping(uint256 => uint256) internal _nftIdToLpId;

    ///@dev Stores how many NFTs each Lp Position owns in the pool
    mapping(uint256 => uint256) internal _lpIdToNftBalance;

    ///@dev Stores how much erc20 liquidity that a given Lp Position owns within the pool.
    ///@dev Also stores list of all LP Position Token IDs representing liquidity in this specific DittoPool:
    ///   a position that has 0 tokens will return 0 but still will be included in .tryGet, .contains() and .length()
    EnumerableMap.UintToUintMap internal _lpIdToTokenBalance;

    ///@dev LP Position NFT contract that tokenizes liquidity provisions in the protocol
    LpNft internal _lpNft;
    ///@dev Permitter contract that decides which NFT tokenIds are permitted in this pool. If not set, all ids allowed
    IPermitter internal _permitter;

    ///@dev flag to prevent pool variables from being set multiple times. Pack with previous address.
    bool internal _initialized;

    ///@dev The ERC721 collection stored in this pool
    IERC721 internal _nft;
    ///@dev The ERC20 collection stored in this pool
    ERC20 internal _token;
    ///@dev The DittoPoolFactory contract that created this pool. Used to fetch up to date protocol fee values
    IDittoPoolFactory internal _dittoPoolFactory;

    ///@dev The fee charged by and paid to the administrator of this pool on each trade. Packed with previous address.
    uint96 internal _feeAdmin;

    ///@dev The recipient address of admin fee.
    address internal _adminFeeRecipient;

    ///@dev The lp fee charged on trades and provided to the liquidit provider. Packed with previous address.
    uint96 internal _feeLp;

    ///@dev A variable used differently by each bonding curve type to update the price after each trade
    uint128 internal _delta;
    ///@dev The current price of the pool, used differently by each bonding curve type
    uint128 internal _basePrice;

    ///@dev the maximum permissible admin fee and Lp value (both capped at 10%)
    uint96 internal constant MAX_FEE = 0.10e18;

    ///@dev which DittoPoolTemplate address was used when creating this pool
    address internal _template;

    // ***************************************************************
    // * ========================= EVENTS ========================== *
    // ***************************************************************
    event DittoPoolMainPoolInitialized(address template, address lpNft, address permitter);
    event DittoPoolMainAdminChangedBasePrice(uint128 newBasePrice);
    event DittoPoolMainAdminChangedDelta(uint128 newDelta);
    event DittoPoolMainAdminChangedAdminFeeRecipient(address adminFeeRecipient);
    event DittoPoolMainAdminChangedAdminFee(uint256 newAdminFee);
    event DittoPoolMainAdminChangedLpFee(uint256 newLpFee);

    // ***************************************************************
    // * ========================= ERRORS ========================== *
    // ***************************************************************

    error DittoPoolMainInvalidAdminFeeRecipient();
    error DittoPoolMainInvalidPermitterData();
    error DittoPoolMainAlreadyInitialized();
    error DittoPoolMainInvalidBasePrice(uint128 basePrice);
    error DittoPoolMainInvalidDelta(uint128 delta);
    error DittoPoolMainInvalidOwnerOperation();
    error DittoPoolMainNoDirectNftTransfers();
    error DittoPoolMainInvalidMsgSender();
    error DittoPoolMainInvalidFee();

    // ***************************************************************
    // * ================ OWNERSHIP FUNCTIONS ====================== *
    // ***************************************************************

    ///@inheritdoc OwnerTwoStep
    function owner() public view virtual override(IOwnerTwoStep, OwnerTwoStep) returns (address) {
        if(_isPrivatePool) {
            return _lpNft.ownerOf(_privatePoolOwnerLpId);
        }
        return OwnerTwoStep.owner();
    }

    ///@inheritdoc OwnerTwoStep
    function _onlyOwner() internal view override(OwnerTwoStep) {
        if(msg.sender != owner()) {
            revert DittoPoolMainInvalidMsgSender();
        }
    }

    ///@inheritdoc OwnerTwoStep
    function acceptOwnership() public override (IOwnerTwoStep, OwnerTwoStep) nonReentrant onlyPendingOwner {
        if(_isPrivatePool) {
            revert DittoPoolMainInvalidOwnerOperation();
        }
        super.acceptOwnership();
        _lpNft.emitMetadataUpdateForAll();
    }

    // ***************************************************************
    // * ============= CONSTRUCTOR AND MODIFIERS =================== *
    // ***************************************************************

    /**
     * @inheritdoc IDittoPool
     */
    function initPool(
        PoolTemplate calldata params_,
        address template_,
        LpNft lpNft_,
        IPermitter permitter_
    ) external {
        // CHECK PRECONDITIONS
        if (_initialized) {
            revert DittoPoolMainAlreadyInitialized();
        }
        _initialized = true;

        // SET STATE
        _isPrivatePool = params_.isPrivatePool;
        _nft = IERC721(params_.nft);
        _token = ERC20(params_.token);
        _lpNft = lpNft_;
        _permitter = permitter_;
        _changeFeeLp(params_.feeLp);
        _changeFeeAdmin(params_.feeAdmin);
        _adminChangeDelta(params_.delta);
        _adminChangeBasePrice(params_.basePrice);
        _transferOwnership(params_.owner);
        _adminFeeRecipient = params_.owner;
        _dittoPoolFactory = IDittoPoolFactory(msg.sender);
        _template = template_;

        _initializeCustomPoolData(params_.templateInitData);

        emit DittoPoolMainPoolInitialized(template_, address(lpNft_), address(permitter_));
    }

    // ***************************************************************
    // * =============== ADMINISTRATIVE FUNCTIONS ================== *
    // ***************************************************************

    ///@inheritdoc IDittoPool
    function changeBasePrice(uint128 newBasePrice_) external virtual onlyOwner {
        _adminChangeBasePrice(newBasePrice_);
    }

    ///@inheritdoc IDittoPool
    function changeDelta(uint128 newDelta_) external virtual onlyOwner {
        _adminChangeDelta(newDelta_);
    }

    ///@inheritdoc IDittoPool
    function changeLpFee(uint96 newFeeLp_) external onlyOwner {
        _changeFeeLp(newFeeLp_);
    }

    ///@inheritdoc IDittoPool
    function changeAdminFee(uint96 newFeeAdmin_) external onlyOwner {
        _changeFeeAdmin(newFeeAdmin_);
    }

    ///@inheritdoc IDittoPool
    function changeAdminFeeRecipient(address newAdminFeeRecipient_) external onlyOwner {
        if (newAdminFeeRecipient_ == address(0)) {
            revert DittoPoolMainInvalidAdminFeeRecipient();
        }

        _adminFeeRecipient = newAdminFeeRecipient_;

        emit DittoPoolMainAdminChangedAdminFeeRecipient(newAdminFeeRecipient_);
    }

    // ***************************************************************
    // * ======= EXTERNALLY CALLABLE READ-ONLY VIEW FUNCTIONS ====== *
    // ***************************************************************

    ///@inheritdoc IDittoPool
    function isPrivatePool() external view returns (bool isPrivatePool_) {
        isPrivatePool_ = _isPrivatePool;
    }

    ///@inheritdoc IDittoPool
    function initialized() external view returns (bool) {
        return _initialized;
    }

    ///@inheritdoc IDittoPool
    function template() external view returns (address) {
        return _template;
    }

    ///@inheritdoc IDittoPool
    function adminFee() external view returns (uint96 feeAdmin_) {
        feeAdmin_ = _feeAdmin;
    }

    ///@inheritdoc IDittoPool
    function lpFee() external view returns (uint96 feeLp_) {
        feeLp_ = _feeLp;
    }

    ///@inheritdoc IDittoPool
    function protocolFee() external view returns (uint256 feeProtocol_) {
        feeProtocol_ = _dittoPoolFactory.getProtocolFee();
    }

    ///@inheritdoc IDittoPool
    function fee() public view returns (uint256 fee_) {
        fee_ = _feeLp + _feeAdmin + _dittoPoolFactory.getProtocolFee();
    }

    ///@inheritdoc IDittoPool
    function delta() external view returns (uint128) {
        return _delta;
    }

    ///@inheritdoc IDittoPool
    function basePrice() external view returns (uint128) {
        return _basePrice;
    }

    ///@inheritdoc IDittoPool
    function dittoPoolFactory() external view returns (address) {
        return address(_dittoPoolFactory);
    }

    ///@inheritdoc IDittoPool
    function adminFeeRecipient() external view returns (address) {
        return _adminFeeRecipient;
    }

    ///@inheritdoc IDittoPool
    function getLpNft() external view returns (address) {
        return address(_lpNft);
    }

    ///@inheritdoc IDittoPool
    function nft() external view returns (IERC721) {
        return _nft;
    }

    ///@inheritdoc IDittoPool
    function token() external view returns (address) {
        return address(_token);
    }

    ///@inheritdoc IDittoPool
    function permitter() public view returns (IPermitter) {
        return _permitter;
    }

    ///@inheritdoc IDittoPool
    function getTokenBalanceForLpId(uint256 lpId_) public view returns (uint256 tokenBalance) {
        (, tokenBalance) = _lpIdToTokenBalance.tryGet(lpId_);
    }

    ///@inheritdoc IDittoPool
    function getNftIdsForLpId(uint256 lpId_) public view returns (uint256[] memory nftIds) {
        nftIds = new uint256[](_lpIdToNftBalance[lpId_]);

        uint256 nftId;
        uint256 nftIdIndex;
        uint256 countOwnedNftIds = _poolOwnedNftIds.length();

        for (uint256 i = 0; i < countOwnedNftIds;) {
            nftId = _poolOwnedNftIds.at(i);
            if (lpId_ == _nftIdToLpId[nftId]) {
                nftIds[nftIdIndex] = nftId;
                unchecked {
                    ++nftIdIndex;
                }
            }
            unchecked {
                ++i;
            }
        }
    }

    ///@inheritdoc IDittoPool
    function getNftCountForLpId(uint256 lpId_) public view returns (uint256) {
        return _lpIdToNftBalance[lpId_];
    }

    ///@inheritdoc IDittoPool
    function getTotalBalanceForLpId(uint256 lpId_)
        public
        view
        returns (uint256 tokenBalance, uint256 nftBalance)
    {
        (, tokenBalance) = _lpIdToTokenBalance.tryGet(lpId_);
        nftBalance = _lpIdToNftBalance[lpId_];
    }

    ///@inheritdoc IDittoPool
    function getLpIdForNftId(uint256 nftId_) public view returns (uint256 lpId) {
        lpId = _nftIdToLpId[nftId_];
    }

    ///@inheritdoc IDittoPool
    function getAllPoolHeldNftIds() external view returns (uint256[] memory) {
        return _poolOwnedNftIds.values();
    }

    ///@inheritdoc IDittoPool
    function getPoolTotalNftBalance() external view returns (uint256) {
        return _poolOwnedNftIds.length();
    }

    ///@inheritdoc IDittoPool
    function getAllPoolLpIds() external view returns (uint256[] memory lpIds) {
        uint256 countLpIds = _lpIdToTokenBalance.length();
        lpIds = new uint256[](countLpIds);

        for (uint256 i = 0; i < countLpIds;) {
            (lpIds[i],) = _lpIdToTokenBalance.at(i);
            unchecked {
                ++i;
            }
        }
    }

    ///@inheritdoc IDittoPool
    function getPoolTotalTokenBalance() external view returns (uint256 totalTokenBalance) {
        uint256 countLpIds = _lpIdToTokenBalance.length();
        uint256 tokenBalance;
        for (uint256 i = 0; i < countLpIds;) {
            (, tokenBalance) = _lpIdToTokenBalance.at(i);
            totalTokenBalance += tokenBalance;
            unchecked {
                ++i;
            }
        }
    }

    ///@inheritdoc IDittoPool
    function getAllLpIdTokenBalances()
        external
        view
        returns (LpIdToTokenBalance[] memory balances)
    {
        uint256 countLpIds = _lpIdToTokenBalance.length();
        balances = new LpIdToTokenBalance[](countLpIds);

        for (uint256 i = 0; i < countLpIds;) {
            (balances[i].lpId, balances[i].tokenBalance) = _lpIdToTokenBalance.at(i);
            unchecked {
                ++i;
            }
        }
    }

    // ***************************************************************
    // * ============= INTERNAL HELPER FUNCTIONS =================== *
    // ***************************************************************

    /**
     * @dev multiply two values that are scaled by 1e18
     */
    function _mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return Math.mulDiv(a, b, 1e18);
    }

    /**
     * @notice check if the tokens being added to the pool are permitted to be added 
     * @param tokenIds_ the token ids to check
     * @param permitterData_ data to pass to permitter for determining validity (e.g. merkle proofs)
     */
    function _checkPermittedTokens(
        uint256[] calldata tokenIds_,
        bytes calldata permitterData_
    ) internal view {
        if (
            address(_permitter) != address(0)
            && !_permitter.checkPermitterData(tokenIds_, permitterData_)
        ) {
            revert DittoPoolMainInvalidPermitterData();
        }
    }

    /**
     * @notice A function to be called to change the _feeAdmin state variable
     * @param newFeeAdmin_ The proposedvalue.
     */
    function _changeFeeAdmin(uint96 newFeeAdmin_) internal virtual {
        _requireValidFee(newFeeAdmin_);
        _feeAdmin = newFeeAdmin_;
        emit DittoPoolMainAdminChangedAdminFee(newFeeAdmin_);
    }

    /**
     * @notice A function to be called to change the _feeLp state variable
     * @param newFeeLp_ The proposed value.
     */
    function _changeFeeLp(uint96 newFeeLp_) internal virtual {
        _requireValidFee(newFeeLp_);
        _feeLp = newFeeLp_;
        emit DittoPoolMainAdminChangedLpFee(newFeeLp_);
    }

    /**
     * @dev Ensure the proosed admin fee is below the max threshold (0.10e18)
     */
    function _requireValidFee(uint96 fee_) internal pure {
        if (fee_ > MAX_FEE) {
            revert DittoPoolMainInvalidFee();
        }
    }

    /**
     * @notice Helper function to change the base price of the pool used by extending contracts
     * @param newBasePrice_ The new base price to set
     */
    function _changeBasePrice(uint128 newBasePrice_) internal {
        if (_invalidBasePrice(newBasePrice_)) {
            revert DittoPoolMainInvalidBasePrice(newBasePrice_);
        }
        _basePrice = newBasePrice_;
    }

    /**
     * @notice Helper function to update the pool's basePrice and log
     * 
     * @param newBasePrice_ The new base price to set
     */
    function _adminChangeBasePrice(uint128 newBasePrice_) internal {
        _changeBasePrice(newBasePrice_);

        emit DittoPoolMainAdminChangedBasePrice(newBasePrice_);
    }

    /**
     * @notice Helper function to change the delta of the pool used by extending contracts
     * @param newDelta_ The new delta to set
     */
    function _changeDelta(uint128 newDelta_) internal {
        if (_invalidDelta(newDelta_)) {
            revert DittoPoolMainInvalidDelta(newDelta_);
        }
        _delta = newDelta_;
    }

    /**
     * @notice Helper function to update the pool's delta and log
     * 
     * @param newDelta_ The new delta to set
     */
    function _adminChangeDelta(uint128 newDelta_) internal {
        _changeDelta(newDelta_);

        emit DittoPoolMainAdminChangedDelta(newDelta_);
    }

    // ***************************************************************
    // * ================== CURVE CUSTOM HOOKS ===================== *
    // ***************************************************************

    /**
     * @notice A function to be called when the pool is initialized. Each curve type
     *   can choose to override this function to introduce custom behavior. 
     */
    function _initializeCustomPoolData(bytes calldata /*templateInitData*/) internal virtual { }

    /**
     * @notice A function to be called when nft liquidity is added. Each curve type
     *   can choose to override this function to introduce custom behavior.
     * @param count_ The count of nft liquidity added.
     */
    function _nftLiquidityAdded(uint256 count_) internal virtual { }

    /**
     * @notice A function to be called when nft liquidity is removed. Each curve type
     *   can choose to override this function to introduce custom behavior.
     * @param count_ The count of nft liquidity removed.
     */
    function _nftLiquidityRemoved(uint256 count_) internal virtual { }

    /**
     * @notice A function to be called when token liquidity is added. Each curve type
     *   can choose to override this function to introduce custom behavior.
     * @param count_ The count of token liquidity added.
     */
    function _tokenLiquidityAdded(uint256 count_) internal virtual { }

    /**
     * @notice A function to be called when token liquidity is removed. Each curve type
     *   can choose to override this function to introduce custom behavior.
     * @param count_ The count of token liquidity removed.
     */
    function _tokenLiquidityRemoved(uint256 count_) internal virtual { }

    /**
     * @notice Validates if a delta value is valid for the curve. The criteria for
     * validity can be different for each type of curve, for instance ExponentialCurve
     * requires delta to be greater than 1.
     * @param delta_ The delta value to be validated
     * @return valid True if delta is invalid, false otherwise
     */
    function _invalidDelta(uint128 delta_) internal pure virtual returns (bool valid);

    /**
     * @notice Validates if a new base price is valid for the curve.
     *   Spot price is generally assumed to be the immediate sell price of 1 NFT to the pool,
     *   in units of the pool's paired token.
     * @param newBasePrice_ The new base price to be set
     * @return valid True if the new base price is invalid, false otherwise
     */
    function _invalidBasePrice(uint128 newBasePrice_) internal pure virtual returns (bool valid);

    // ***************************************************************
    // * ================== ON ERC721 RECEIVED ===================== *
    // ***************************************************************
    ///@inheritdoc IDittoPool
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        revert DittoPoolMainNoDirectNftTransfers();
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

import { IDittoPool } from "../interface/IDittoPool.sol";
import { DittoPoolMain } from "./DittoPoolMain.sol";
import { ERC20 } from "../../lib/solmate/src/tokens/ERC20.sol";
import { SafeTransferLib } from "../../lib/solmate/src/utils/SafeTransferLib.sol";
import { ReentrancyGuard } from
    "../../lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import { EnumerableSet } from
    "../../lib/openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";
import { EnumerableMap } from
    "../../lib/openzeppelin-contracts/contracts/utils/structs/EnumerableMap.sol";

/**
 * @title DittoPool
 * @notice Parent contract defines common functions for DittoPool AMM shared liquidity trading pools.
 */
abstract contract DittoPoolMarketMake is DittoPoolMain {
    using SafeTransferLib for ERC20;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToUintMap;

    // ***************************************************************
    // * ========================= EVENTS ========================== *
    // ***************************************************************

    event DittoPoolMarketMakeLiquidityAdded(
        address liquidityProvider, 
        uint256 lpId, 
        uint256[] tokenIds, 
        uint256 tokenDepositAmount,
        bytes referrer
    );
    event DittoPoolMarketMakeLiquidityRemoved(
        uint256 lpId, 
        uint256[] nftIds, 
        uint256 tokenWithdrawAmount
    );

    // ***************************************************************
    // * ========================= ERRORS ========================== *
    // ***************************************************************
    error DittoPoolMarketMakeMustDepositLiquidity();
    error DittoPoolMarketMakeWrongPoolForLpId();
    error DittoPoolMarketMakeNotAuthorizedForLpId();
    error DittoPoolMarketMakeInsufficientBalance();
    error DittoPoolMarketMakeInvalidNftTokenId();
    error DittoPoolMarketMakeOneLpPerPrivatePool();

    // ***************************************************************
    // * ======= FUNCTIONS TO MARKET MAKE: ADD LIQUIDITY =========== *
    // ***************************************************************

    ///@inheritdoc IDittoPool
    function createLiquidity(
        address lpRecipient_,
        uint256[] calldata nftIdList_,
        uint256 tokenDepositAmount_,
        bytes calldata permitterData_,
        bytes calldata referrer_
    ) external nonReentrant returns (uint256 lpId) {
        if (tokenDepositAmount_ == 0 && nftIdList_.length == 0) {
            revert DittoPoolMarketMakeMustDepositLiquidity();
        }
        lpId = _lpNft.mint(lpRecipient_);
        if(_isPrivatePool) {
            if(_privatePoolOwnerLpId != 0) {
                revert DittoPoolMarketMakeOneLpPerPrivatePool();
            } else {
                _privatePoolOwnerLpId = lpId;
            }
        }
        _lpIdToTokenBalance.set(lpId, 0); // tracking full set of lpIds for this pool
        _transferInLiquidity(lpId, nftIdList_, tokenDepositAmount_, permitterData_, referrer_);
    }

    ///@inheritdoc IDittoPool
    function addLiquidity(
        uint256 lpId_,
        uint256[] calldata nftIdList_,
        uint256 tokenDepositAmount_,
        bytes calldata permitterData_,
        bytes calldata referrer_
    ) external nonReentrant {
        if(_isPrivatePool){
            _onlyOwner();
            if(_privatePoolOwnerLpId != lpId_){
                revert DittoPoolMarketMakeOneLpPerPrivatePool();
            }
        }
        if (tokenDepositAmount_ == 0 && nftIdList_.length == 0) {
            revert DittoPoolMarketMakeMustDepositLiquidity();
        }
        if (address(_lpNft.getPoolForLpId(lpId_)) != address(this)) {
            revert DittoPoolMarketMakeWrongPoolForLpId();
        }
        _transferInLiquidity(lpId_, nftIdList_, tokenDepositAmount_, permitterData_, referrer_);
    }

    /**
     * @notice Helper function to deposits NFTS+ERC20 liquidity into the pool. See the external function documentation.
     * @dev If the msg.sender has not set approvals for this contract then the transaction will fail.
     */
    function _transferInLiquidity(
        uint256 lpId_,
        uint256[] calldata nftIdList_,
        uint256 tokenDepositAmount_,
        bytes calldata permitterData_,
        bytes calldata referrer_
    ) internal {
        uint256 nftId;
        uint256 countNftIds = nftIdList_.length;

        // TRANSFER IN NFT LIQUIDITY
        if (countNftIds > 0) {
            _checkPermittedTokens(nftIdList_, permitterData_);

            for (uint256 i = 0; i < countNftIds;) {
                nftId = nftIdList_[i];
                _nft.transferFrom(msg.sender, address(this), nftId);
                _poolOwnedNftIds.add(nftId);
                _nftIdToLpId[nftId] = lpId_;

                unchecked {
                    ++i;
                }
            }

            _lpIdToNftBalance[lpId_] += countNftIds;
            _nftLiquidityAdded(countNftIds);
        }

        // TRANSFER IN TOKEN LIQUIDITY
        if (tokenDepositAmount_ > 0) {
            _token.transferFrom(msg.sender, address(this), tokenDepositAmount_);

            (, uint256 currentTokenBalance) = _lpIdToTokenBalance.tryGet(lpId_);
            _lpIdToTokenBalance.set(lpId_, currentTokenBalance + tokenDepositAmount_);
            _tokenLiquidityAdded(tokenDepositAmount_);
        }

        emit DittoPoolMarketMakeLiquidityAdded(msg.sender, lpId_, nftIdList_, tokenDepositAmount_, referrer_);
    }

    // ***************************************************************
    // * ===== FUNCTIONS TO MARKET MAKE: REMOVE LIQUIDITY ========== *
    // ***************************************************************

    ///@inheritdoc IDittoPool
    function pullLiquidity(
        address withdrawalAddress_,
        uint256 lpId_,
        uint256[] calldata nftIdList_,
        uint256 tokenWithdrawAmount_
    ) external nonReentrant {
        // CHECK INPUTS
        (IDittoPool pool, address lpNftOwner) = _lpNft.getPoolAndOwnerForLpId(lpId_);
        if (address(pool) != address(this)) {
            revert DittoPoolMarketMakeWrongPoolForLpId();
        }
        if (lpNftOwner != msg.sender && !_lpNft.isApproved(msg.sender, lpId_)) {
            revert DittoPoolMarketMakeNotAuthorizedForLpId();
        }

        // TRANSFER OUT NFT LIQUIDITY
        {
            uint256 countNftIds = nftIdList_.length;
            for (uint256 i = 0; i < countNftIds;) {
                uint256 nftId = nftIdList_[i];
                if (_nftIdToLpId[nftId] != lpId_) {
                    revert DittoPoolMarketMakeInvalidNftTokenId();
                }

                _nft.safeTransferFrom(address(this), withdrawalAddress_, nftId);

                _poolOwnedNftIds.remove(nftId);
                delete _nftIdToLpId[nftId];

                unchecked {
                    ++i;
                }
            }

            _lpIdToNftBalance[lpId_] -= countNftIds;
            _nftLiquidityRemoved(countNftIds);
        }

        // TRANSFER OUT TOKEN LIQUIDITY
        (, uint256 currentTokenBalance) = _lpIdToTokenBalance.tryGet(lpId_);
        if (tokenWithdrawAmount_ > 0) {
            if (tokenWithdrawAmount_ > currentTokenBalance) {
                revert DittoPoolMarketMakeInsufficientBalance();
            }

            _token.safeTransfer(withdrawalAddress_, tokenWithdrawAmount_);

            currentTokenBalance -= tokenWithdrawAmount_;
            _lpIdToTokenBalance.set(lpId_, currentTokenBalance);

            _tokenLiquidityRemoved(tokenWithdrawAmount_);
        }

        // HANDLE LP POSITION BURNING
        if (_lpIdToNftBalance[lpId_] == 0 && currentTokenBalance == 0) {
            _lpNft.burn(lpId_);
            _lpIdToTokenBalance.remove(lpId_); // tracking full set of lpIds for this pool
        }

        emit DittoPoolMarketMakeLiquidityRemoved(lpId_, nftIdList_, tokenWithdrawAmount_);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

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
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
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
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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
     * @dev Returns the number of values in the set. O(1).
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableMap.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableMap.js.

pragma solidity ^0.8.0;

import "./EnumerableSet.sol";

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * The following map types are supported:
 *
 * - `uint256 -> address` (`UintToAddressMap`) since v3.0.0
 * - `address -> uint256` (`AddressToUintMap`) since v4.6.0
 * - `bytes32 -> bytes32` (`Bytes32ToBytes32Map`) since v4.6.0
 * - `uint256 -> uint256` (`UintToUintMap`) since v4.7.0
 * - `bytes32 -> uint256` (`Bytes32ToUintMap`) since v4.7.0
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableMap, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableMap.
 * ====
 */
library EnumerableMap {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct Bytes32ToBytes32Map {
        // Storage of keys
        EnumerableSet.Bytes32Set _keys;
        mapping(bytes32 => bytes32) _values;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        Bytes32ToBytes32Map storage map,
        bytes32 key,
        bytes32 value
    ) internal returns (bool) {
        map._values[key] = value;
        return map._keys.add(key);
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Bytes32ToBytes32Map storage map, bytes32 key) internal returns (bool) {
        delete map._values[key];
        return map._keys.remove(key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool) {
        return map._keys.contains(key);
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function length(Bytes32ToBytes32Map storage map) internal view returns (uint256) {
        return map._keys.length();
    }

    /**
     * @dev Returns the key-value pair stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of entries inside the
     * array, and it may change when more entries are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32ToBytes32Map storage map, uint256 index) internal view returns (bytes32, bytes32) {
        bytes32 key = map._keys.at(index);
        return (key, map._values[key]);
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool, bytes32) {
        bytes32 value = map._values[key];
        if (value == bytes32(0)) {
            return (contains(map, key), bytes32(0));
        } else {
            return (true, value);
        }
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || contains(map, key), "EnumerableMap: nonexistent key");
        return value;
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        Bytes32ToBytes32Map storage map,
        bytes32 key,
        string memory errorMessage
    ) internal view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || contains(map, key), errorMessage);
        return value;
    }

    // UintToUintMap

    struct UintToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToUintMap storage map,
        uint256 key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, bytes32(key), bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToUintMap storage map, uint256 key) internal returns (bool) {
        return remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToUintMap storage map, uint256 key) internal view returns (bool) {
        return contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToUintMap storage map, uint256 index) internal view returns (uint256, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (uint256(key), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(UintToUintMap storage map, uint256 key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToUintMap storage map, uint256 key) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(key)));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToUintMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(key), errorMessage));
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToAddressMap storage map,
        uint256 key,
        address value
    ) internal returns (bool) {
        return set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToAddressMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (address) {
        return address(uint160(uint256(get(map._inner, bytes32(key), errorMessage))));
    }

    // AddressToUintMap

    struct AddressToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        AddressToUintMap storage map,
        address key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, bytes32(uint256(uint160(key))), bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(AddressToUintMap storage map, address key) internal returns (bool) {
        return remove(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(AddressToUintMap storage map, address key) internal view returns (bool) {
        return contains(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(AddressToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressToUintMap storage map, uint256 index) internal view returns (address, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (address(uint160(uint256(key))), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(AddressToUintMap storage map, address key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(uint256(uint160(key))));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(AddressToUintMap storage map, address key) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(uint256(uint160(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        AddressToUintMap storage map,
        address key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(uint256(uint160(key))), errorMessage));
    }

    // Bytes32ToUintMap

    struct Bytes32ToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        Bytes32ToUintMap storage map,
        bytes32 key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, key, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Bytes32ToUintMap storage map, bytes32 key) internal returns (bool) {
        return remove(map._inner, key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Bytes32ToUintMap storage map, bytes32 key) internal view returns (bool) {
        return contains(map._inner, key);
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(Bytes32ToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32ToUintMap storage map, uint256 index) internal view returns (bytes32, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (key, uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(Bytes32ToUintMap storage map, bytes32 key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, key);
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Bytes32ToUintMap storage map, bytes32 key) internal view returns (uint256) {
        return uint256(get(map._inner, key));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        Bytes32ToUintMap storage map,
        bytes32 key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, key, errorMessage));
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @author Modified from Gnosis (https://github.com/gnosis/gp-v2-contracts/blob/main/src/contracts/libraries/GPv2SafeERC20.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
library SafeTransferLib {
    /*///////////////////////////////////////////////////////////////
                            ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool callStatus;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            callStatus := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(callStatus, "ETH_TRANSFER_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                           ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "from" argument.
            mstore(add(freeMemoryPointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 100 because the calldata length is 4 + 32 * 3.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 100, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "APPROVE_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                         INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    function didLastOptionalReturnCallSucceed(bool callStatus) private pure returns (bool success) {
        assembly {
            // Get how many bytes the call returned.
            let returnDataSize := returndatasize()

            // If the call reverted:
            if iszero(callStatus) {
                // Copy the revert message into memory.
                returndatacopy(0, 0, returnDataSize)

                // Revert with the same message.
                revert(0, returnDataSize)
            }

            switch returnDataSize
            case 32 {
                // Copy the return data into memory.
                returndatacopy(0, 0, returnDataSize)

                // Set success to whether it returned true.
                success := iszero(iszero(mload(0)))
            }
            case 0 {
                // There was no return data.
                success := 1
            }
            default {
                // It returned some malformed input.
                success := 0
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                             EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
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

    /*///////////////////////////////////////////////////////////////
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

    /*///////////////////////////////////////////////////////////////
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
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);

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

    /*///////////////////////////////////////////////////////////////
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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

import {
    Swap,
    NftInSwap,
    RobustSwap,
    RobustNftInSwap,
    ComplexSwap,
    RobustComplexSwap
} from "../struct/RouterStructs.sol";
import { IERC721 } from "../../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import { ERC20 } from "../../lib/solmate/src/tokens/ERC20.sol";

/**
 * @title Ditto Swap Router Interface
 * @notice Performs swaps between Nfts and ERC20 tokens, across multiple pools, or more complicated multi-swap paths
 * @dev All swaps assume that a single ERC20 token is used for all the pools involved.
 * Swapping using multiple tokens in the same transaction is possible, but the slippage checks and the return values
 * will be meaningless, and may lead to undefined behavior.
 * @dev UX: The sender should grant infinite token approvals to the router in order for Nft-to-Nft swaps to work smoothly.
 * @dev This router has a notion of robust, and non-robust swaps. "Robust" versions of a swap will never revert due to
 * slippage. Instead, users specify a per-swap max cost. If the price changes more than the user specifies, no swap is
 * attempted. This allows users to specify a batch of swaps, and execute as many of them as possible.
 * On non-robust swaps, if any slippage check per trade fails in the chain, the entire transaction reverts.
 */
interface IDittoRouter {
    // ***************************************************************
    // * ============ TRADING ERC20 TOKENS FOR STUFF =============== *
    // ***************************************************************

    /**
     * @notice Swaps ERC20 tokens into specific Nfts using multiple pools.
     * @param swapList The list of pools to trade with and the IDs of the Nfts to buy from each.
     * @param inputAmount The amount of ERC20 tokens to add to the ERC20-to-Nft swaps
     * @param nftRecipient The address that will receive the Nft output
     * @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
     * @return remainingValue The unspent token amount
     */
    function swapTokensForNfts(
        Swap[] calldata swapList,
        uint256 inputAmount,
        address nftRecipient,
        uint256 deadline
    ) external returns (uint256 remainingValue);

    /**
     * @notice Swaps as many ERC20 tokens for specific Nfts as possible, respecting the per-swap max cost.
     * @param swapList The list of pools to trade with and the IDs of the Nfts to buy from each.
     * @param inputAmount The amount of ERC20 tokens to add to the ERC20-to-Nft swaps
     *
     * @param nftRecipient The address that will receive the Nft output
     * @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
     * @return remainingValue The unspent token amount
     */
    function robustSwapTokensForNfts(
        RobustSwap[] calldata swapList,
        uint256 inputAmount,
        address nftRecipient,
        uint256 deadline
    ) external returns (uint256 remainingValue);

    /**
     * @notice Buys Nfts with ERC20, and sells them for tokens in one transaction
     * @param params All the parameters for the swap (packed in struct to avoid stack too deep), containing:
     * - ethToNftSwapList The list of Nfts to buy
     * - nftToTokenSwapList The list of Nfts to sell
     * - inputAmount The max amount of tokens to send (if ERC20)
     * - tokenRecipient The address that receives tokens from the Nfts sold
     * - nftRecipient The address that receives Nfts
     * - deadline UNIX timestamp deadline for the swap
     */
    function robustSwapTokensForNftsAndNftsForTokens(RobustComplexSwap calldata params)
        external
        returns (uint256 remainingValue, uint256 outputAmount);

    // ***************************************************************
    // * ================= TRADING NFTs FOR STUFF ================== *
    // ***************************************************************

    /**
     * @notice Swaps Nfts into ETH/ERC20 using multiple pools.
     * @param swapList The list of pools to trade with and the IDs of the Nfts to sell to each.
     * @param minOutput The minimum acceptable total tokens received
     * @param tokenRecipient The address that will receive the token output
     * @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
     * @return outputAmount The total tokens received
     */
    function swapNftsForTokens(
        NftInSwap[] calldata swapList,
        uint256 minOutput,
        address tokenRecipient,
        uint256 deadline
    ) external returns (uint256 outputAmount);

    /**
     * @notice Swaps as many Nfts for tokens as possible, respecting the per-swap min output
     * @param swapList The list of pools to trade with and the IDs of the Nfts to sell to each.
     * @param tokenRecipient The address that will receive the token output
     * @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
     * @return outputAmount The total ETH/ERC20 received
     */
    function robustSwapNftsForTokens(
        RobustNftInSwap[] calldata swapList,
        address tokenRecipient,
        uint256 deadline
    ) external returns (uint256 outputAmount);

    /**
     * @notice Swaps one set of Nfts into another set of specific Nfts using multiple pools, using
     * an ERC20 token as the intermediary.
     * @param trade The struct containing all Nft-to-ERC20 swaps and ERC20-to-Nft swaps.
     * @param inputAmount The amount of ERC20 tokens to add to the ERC20-to-Nft swaps
     * @param minOutput The minimum acceptable total excess tokens received
     * @param nftRecipient The address that will receive the Nft output
     * @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
     * @return outputAmount The total ERC20 tokens received
     */
    function swapNftsForSpecificNftsThroughTokens(
        ComplexSwap calldata trade,
        uint256 inputAmount,
        uint256 minOutput,
        address nftRecipient,
        uint256 deadline
    ) external returns (uint256 outputAmount);

    // ***************************************************************
    // * ================= RESTRICTED FUNCTIONS ==================== *
    // ***************************************************************

    /**
     * @notice Allows pool contracts to transfer ERC20 tokens directly from
     * the sender, in order to minimize the number of token transfers.
     * @dev Only callable by valid IDittoPools.
     * @param token The ERC20 token to transfer
     * @param from The address to transfer tokens from
     * @param to The address to transfer tokens to
     * @param amount The amount of tokens to transfer
     */
    function poolTransferErc20From(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) external;

    /**
     * @notice Allows pool contracts to transfer ERC721 NFTs directly from
     * the sender, in order to minimize the number of token transfers.
     * @dev Only callable by valid IDittoPools.
     * @param nft The ERC721 NFT to transfer
     * @param from The address to transfer tokens from
     * @param to The address to transfer tokens to
     * @param id The ID of the NFT to transfer
     */
    function poolTransferNftFrom(IERC721 nft, address from, address to, uint256 id) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

import { IERC4906 } from "./IERC4906.sol";
import { IDittoPool } from "./IDittoPool.sol";
import { IDittoPoolFactory } from "./IDittoPoolFactory.sol";
import { IMetadataGenerator } from "./IMetadataGenerator.sol";
import { IERC721 } from "../../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

interface ILpNft is IERC4906 {
    // * =============== State Changing Functions ================== *

    /**
     * @notice Allows an admin to update the metadata generator through the pool factory.
     * @dev only the Ditto Pool Factory is allowed to call this function
     * @param metadataGenerator_ The address of the metadata generator contract.
     */
    function setMetadataGenerator(IMetadataGenerator metadataGenerator_) external;

    /**
     * @notice Allows the factory to whitelist DittoPool contracts as allowed to mint and burn liquidity position NFTs.
     * @dev only the Ditto Pool Factory is allowed to call this function
     * @param dittoPool_ The address of the DittoPool contract to whitelist.
     * @param nft_ The address of the NFT contract that the DittoPool trades.
     */
    function setApprovedDittoPool(address dittoPool_, IERC721 nft_) external;

    /**
     * @notice mint function used to create new LP Position NFTs 
     * @dev only callable by approved DittoPool contracts
     * @param to_ The address of the user who will own the new NFT.
     * @return lpId The tokenId of the newly minted NFT.
     */
    function mint(address to_) external returns (uint256 lpId);

    /**
     * @notice burn function used to destroy LP Position NFTs
     * @dev only callable approved DittoPool contracts
     * @param lpId_ The tokenId of the NFT to burn.
     */
    function burn(uint256 lpId_) external;

    /**
     * @notice Updates LP position NFT metadata on trades, as LP's LP information changes due to the trade
     * @dev see [EIP-4906](https://eips.ethereum.org/EIPS/eip-4906) EIP-721 Metadata Update Extension
     * @dev only callable by approved DittoPool contracts
     * @param lpId_ the tokenId of the NFT who's metadata needs to be updated
     */
    function emitMetadataUpdate(uint256 lpId_) external;

    /**
     * @notice Tells off-chain actors to update LP position NFT metadata for all tokens in the collection
     * @dev see [EIP-4906](https://eips.ethereum.org/EIPS/eip-4906) EIP-721 Metadata Update Extension
     * @dev only callable by approved DittoPool contracts
     */
    function emitMetadataUpdateForAll() external;

    // * ======= EXTERNALLY CALLABLE READ-ONLY VIEW FUNCTIONS ====== *

    /**
     * @notice Tells you whether a given tokenId is allowed to be spent/used by a given spender on behalf of its owner.
     * @dev see EIP-721 approve() and setApprovalForAll() functions
     * @param spender_ The address of the operator/spender to check.
     * @param lpId_ The tokenId of the NFT to check.
     * @return approved Whether the spender is allowed to send or manipulate the NFT.
     */
    function isApproved(address spender_, uint256 lpId_) external view returns (bool);

    /**
     * @notice Check if an address has been approved as a DittoPool on the LpNft contract
     * @param dittoPool_ The address of the DittoPool contract to check.
     * @return approved Whether the DittoPool is approved to mint and burn liquidity position NFTs.
     */
    function isApprovedDittoPool(address dittoPool_) external view returns (bool);

    /**
     * @notice Returns which DittoPool applies to a given LP Position NFT tokenId.
     * @param lpId_ The LP Position tokenId to get info for.
     * @return pool The DittoPool contract that the LP Position NFT is tied to.
     */
    function getPoolForLpId(uint256 lpId_) external view returns (IDittoPool pool);

    /**
     * @notice Returns the DittoPool and liquidity provider's address for a given LP Position NFT tokenId.
     * @param lpId_ The LP Position tokenId to get info for.
     * @return pool The DittoPool contract that the LP Position NFT is tied to.
     * @return owner The owner of the lpId.
     */
    function getPoolAndOwnerForLpId(uint256 lpId_)
        external
        view
        returns (IDittoPool pool, address owner);

    /**
     * @notice Returns the address of the underlying NFT collection traded by the DittoPool corresponding to an LP Position NFT tokenId.
     * @param lpId_ The LP Position tokenId to get info for.
     * @return nft The address of the underlying NFT collection for that LP position
     */
    function getNftForLpId(uint256 lpId_) external view returns (IERC721);

    /**
     * @notice Returns the amount of ERC20 tokens held by a liquidity provider in a given LP Position.
     * @param lpId_ The LP Position tokenId to get info for.
     * @return value the amount of ERC20 tokens held by the liquidity provider in the given LP Position.
     */
    function getLpValueToken(uint256 lpId_) external view returns (uint256);

    /**
     * @notice Returns the list of NFT Ids (of the underlying NFT collection) held by a liquidity provider in a given LP Position.
     * @param lpId_ The LP Position tokenId to get info for.
     * @return nftIds the list of NFT Ids held by the liquidity provider in the given LP Position.
     */
    function getAllHeldNftIds(uint256 lpId_) external view returns (uint256[] memory);

    /**
     * @notice Returns the count of NFTs held by a liquidity provider in a given LP Position.
     * @param lpId_ The LP Position tokenId to get info for.
     * @return nftCount the count of NFTs held by the liquidity provider in the given LP Position.
     */
    function getNumNftsHeld(uint256 lpId_) external view returns (uint256);

    /**
     * @notice Returns the "value" of an LP positions NFT holdings in ERC20 Tokens,
     *   if it were to be sold at the current base price.
     * @param lpId_ The LP Position tokenId to get info for.
     * @return value the "value" of an LP positions NFT holdings in ERC20 Tokens.
     */
    function getLpValueNft(uint256 lpId_) external view returns (uint256);

    /**
     * @notice Returns the "value" of an LP positions total holdings in ERC20s + NFTs,
     *   if all the Nfts in the holdings were sold at the current base price.
     * @param lpId_ The LP Position tokenId to get info for.
     * @return value the "value" of an LP positions sum total holdings in ERC20s + NFTs.
     */
    function getLpValue(uint256 lpId_) external view returns (uint256);

    /**
     * @notice Returns the address of the DittoPoolFactory contract
     * @return factory the address of the DittoPoolFactory contract
     */
    function dittoPoolFactory() external view returns (IDittoPoolFactory);

    /**
     * @notice returns the next tokenId to be minted
     * @dev NFTs are minted sequentially, starting at tokenId 1
     * @return nextId the next tokenId to be minted
     */
    function nextId() external view returns (uint256);

    /**
     * @notice returns the address of the contract that generates the metadata for LP Position NFTs
     * @return metadataGenerator the address of the contract that generates the metadata for LP Position NFTs
     */
    function metadataGenerator() external view returns (IMetadataGenerator);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

import { IDittoPool } from "./IDittoPool.sol";

/**
 * @title IMetadataGenerator
 * @notice Provides a standard interface for interacting with the MetadataGenerator contract 
 *   to return a base64 encoded tokenURI for a given tokenId.
 */
interface IMetadataGenerator {
    /**
     * @notice Called in the tokenURI() function of the LpNft contract.
     * @param lpId_ The identifier for a liquidity position NFT
     * @param pool_ The DittoPool address associated with this liquidity position NFT
     * @param countToken_ Count of all ERC20 tokens assigned to the owner of the liquidity position NFT in the DittoPool
     * @param countNft_ Count of all NFTs assigned to the owner of the liquidity position NFT in the DittoPool
     * @return tokenUri A distinct Uniform Resource Identifier (URI) for a given asset.
     */
    function payloadTokenUri(
        uint256 lpId_,
        IDittoPool pool_,
        uint256 countToken_,
        uint256 countNft_
    ) external view returns (string memory tokenUri);

    /**
     * @notice Called in the contractURI() function of the LpNft contract.
     * @return contractUri A distinct Uniform Resource Identifier (URI) for a given asset.
     */
    function payloadContractUri() external view returns (string memory contractUri);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

import { PoolTemplate } from "../struct/FactoryTemplates.sol";
import { LpNft } from "../pool/lpNft/LpNft.sol";
import { IOwnerTwoStep } from "./IOwnerTwoStep.sol";
import { IDittoPool } from "./IDittoPool.sol";
import { IDittoRouter } from "./IDittoRouter.sol";
import { IPermitter } from "./IPermitter.sol";
import { IMetadataGenerator } from "./IMetadataGenerator.sol";
import { IPoolManager } from "./IPoolManager.sol";
import { PoolManagerTemplate, PermitterTemplate } from "../struct/FactoryTemplates.sol";

interface IDittoPoolFactory is IOwnerTwoStep {
    // ***************************************************************
    // * ====================== MAIN INTERFACE ===================== *
    // ***************************************************************

    /**
     * @notice Create a ditto pool along with a permitter and pool manager if requested. 
     *
     * @param params_ The pool creation parameters including initial liquidity and fee settings
     *   **uint256 templateIndex** The index of the pool template to clone
     *   **address token** ERC20 token address trading against the nft collection
     *   **address nft** the address of the NFT collection that we are creating a pool for
     *   **uint96 feeLp** the fee percentage paid to LPers when they are the counterparty in a trade
     *   **address owner** The liquidity initial provider and owner of the pool, overwritten by pool manager if present
     *   **uint96 feeAdmin** the fee percentage paid to the pool admin 
     *   **uint128 delta** the delta of the pool, see bonding curve documentation
     *   **uint128 basePrice** the base price of the pool, see bonding curve documentation
     *   **uint256[] nftIdList** the token IDs of NFTs to deposit into the pool as it is created. Empty arrays are allowed
     *   **uint256 initialTokenBalance** the number of ERC20 tokens to transfer to the pool as you create it. Zero is allowed
     *   **bytes initialTemplateData** initial data to pass to the pool contract in its initializer
     * @param poolManagerTemplate_ The template for the pool manager to manage the pool. Provide type(uint256).max to opt out
     * @param permitterTemplate_  The template for the permitter to manage the pool. Provide type(uint256).max to opt out
     * @return dittoPool The newly created DittoPool
     * @return lpId The ID of the LP position NFT representing the initial liquidity deposited, or zero, if none deposited
     * @return poolManager The pool manager or the zero address if none was created
     * @return permitter The permitter or the zero address if none was created
     */
    function createDittoPool(
        PoolTemplate memory params_,
        PoolManagerTemplate calldata poolManagerTemplate_,
        PermitterTemplate calldata permitterTemplate_
    )
        external
        returns (IDittoPool dittoPool, uint256 lpId, IPoolManager poolManager, IPermitter permitter);

    // ***************************************************************
    // * ============== EXTERNAL VIEW FUNCTIONS ==================== *
    // ***************************************************************

    /**
     * @notice Get the list of pool templates that can be used to create new pools
     * @return poolTemplates_ The list of pool templates that can be used to create new pools
     */
    function poolTemplates() external view returns (address[] memory);

    /**
     * @notice Get the list of pool manager templates that can be used to manage a new pool
     * @return poolManagerTemplates_ The list of pool manager templates that can be used to manage a new pool
     */
    function poolManagerTemplates() external view returns (IPoolManager[] memory);

    /**
     * @notice Get the list of permitter templates that can be used to restrict nft ids in a pool
     * @return permitterTemplates_ The list of permitter templates that can be used to restrict nft ids in a pool
     */
    function permitterTemplates() external view returns (IPermitter[] memory);

    /**
     * @notice Check if an address is an approved whitelisted router that can trade with the pools
     * @param potentialRouter_ The address to check if it is a whitelisted router
     * @return isWhitelistedRouter True if the address is a whitelisted router
     */
    function isWhitelistedRouter(address potentialRouter_) external view returns (bool);

    /**
     * @notice Get the protocol fee recipient address
     * @return poolFeeRecipient of the protocol fee recipient
     */
    function protocolFeeRecipient() external view returns (address);

    /**
     * @notice Get the protocol fee multiplier used to calculate fees on all trades 
     * @return protocolFeeMultiplier the multiplier for global protocol fees on all trades
     */
    function getProtocolFee() external view returns (uint96);

    /**
     * @notice The nft used to represent liquidity positions
     */
    function lpNft() external view returns (LpNft lpNft_);

    // ***************************************************************
    // * ==================== ADMIN FUNCTIONS ====================== *
    // ***************************************************************

    /**
     * @notice Admin function to add additional pool templates 
     * @param poolTemplates_ addresses of the new pool templates
     */
    function addPoolTemplates(address[] calldata poolTemplates_) external;

    /**
     * @notice Admin function to add additional pool manager templates
     * @param poolManagerTemplates_ addresses of the new pool manager templates
     */
    function addPoolManagerTemplates(IPoolManager[] calldata poolManagerTemplates_) external;

    /**
     * @notice Admin function to add additional permitter templates
     * @param permitterTemplates_ addresses of the new permitter templates
     */
    function addPermitterTemplates(IPermitter[] calldata permitterTemplates_) external;

    /**
     * @notice Admin function to add additional whitelisted routers
     * @param routers_ addresses of the new routers to whitelist
     */
    function addRouters(IDittoRouter[] calldata routers_) external;

    /**
     * @notice Admin function to set the protocol fee recipient
     * @param feeProtocolRecipient_ address of the new protocol fee recipient
     */
    function setProtocolFeeRecipient(address feeProtocolRecipient_) external;

    /**
     * @notice Admin function to set the protocol fee multiplier used to calculate fees on all trades, base 1e18
     * @param feeProtocol_ the new protocol fee multiplier
     */
    function setProtocolFee(uint96 feeProtocol_) external;

    /**
     * @notice Admin functino to set the metadata generator which is used to generate an svg representing each  NFT
     * @param metadataGenerator_ address of the metadata generator
     */
    function setMetadataGenerator(IMetadataGenerator metadataGenerator_) external;
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

import { IOwnerTwoStep } from "../interface/IOwnerTwoStep.sol";

abstract contract OwnerTwoStep is IOwnerTwoStep {

    /// @dev The owner of the contract
    address private _owner;

    /// @dev The pending owner of the contract
    address private _pendingOwner;

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(msg.sender);
    }

    // ***************************************************************
    // * ========================= EVENTS ========================== *
    // ***************************************************************

    event OwnerTwoStepOwnerStartedTransfer(address currentOwner, address newPendingOwner);
    event OwnerTwoStepPendingOwnerAcceptedTransfer(address newOwner);
    event OwnerTwoStepOwnershipTransferred(address previousOwner, address newOwner);
    event OwnerTwoStepOwnerRenouncedOwnership(address previousOwner);

    // ***************************************************************
    // * ========================= ERRORS ========================== *
    // ***************************************************************

    error OwnerTwoStepNotOwner();
    error OwnerTwoStepNotPendingOwner();

    // ***************************************************************
    // * =================== USER INTERFACE ======================== *
    // ***************************************************************

    ///@inheritdoc IOwnerTwoStep
    function transferOwnership(address newPendingOwner_) public virtual override onlyOwner {
        _pendingOwner = newPendingOwner_;

        emit OwnerTwoStepOwnerStartedTransfer(_owner, newPendingOwner_);
    }

    ///@inheritdoc IOwnerTwoStep
    function acceptOwnership() public virtual override onlyPendingOwner {
        emit OwnerTwoStepPendingOwnerAcceptedTransfer(msg.sender);

        _transferOwnership(msg.sender);
    }

    ///@inheritdoc IOwnerTwoStep
    function renounceOwnership() public virtual onlyOwner {

        emit OwnerTwoStepOwnerRenouncedOwnership(msg.sender);

        _transferOwnership(address(0));
    }

    // ***************************************************************
    // * =================== VIEW FUNCTIONS ======================== *
    // ***************************************************************

    ///@inheritdoc IOwnerTwoStep
    function owner() public view virtual override returns (address) {
        return _owner;
    }

    ///@inheritdoc IOwnerTwoStep
    function pendingOwner() external view override returns (address) {
        return _pendingOwner;
    }

    // ***************************************************************
    // * ===================== MODIFIERS =========================== *
    // ***************************************************************

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    /**
     * @dev Throws if called by any account other than the pending owner.
     */
    modifier onlyPendingOwner {
        if (msg.sender != _pendingOwner) {
            revert OwnerTwoStepNotPendingOwner();
        }
        _;
    }

    // ***************************************************************
    // * ================== INTERNAL HELPERS ======================= *
    // ***************************************************************

    /**
     * @dev Throws if called by any account other than the owner. Saves contract size over copying 
     *   implementation into every function that uses the modifier.
     */
    function _onlyOwner() internal view virtual {
        if (msg.sender != _owner) {
            revert OwnerTwoStepNotOwner();
        }
    }


    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * @param newOwner_ New owner to transfer to
     */
    function _transferOwnership(address newOwner_) internal {
        delete _pendingOwner;

        emit OwnerTwoStepOwnershipTransferred(_owner, newOwner_);

        _owner = newOwner_;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
/// @dev Note that balanceOf does not revert if passed the zero address, in defiance of the ERC.
abstract contract ERC721 {
    /*///////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*///////////////////////////////////////////////////////////////
                          METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*///////////////////////////////////////////////////////////////
                            ERC721 STORAGE                        
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(uint256 => address) public ownerOf;

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*///////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || msg.sender == getApproved[id] || isApprovedForAll[from][msg.sender],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            balanceOf[from]--;

            balanceOf[to]++;
        }

        delete getApproved[id];

        ownerOf[id] = to;

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*///////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            totalSupply++;

            balanceOf[to]++;
        }

        ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = ownerOf[id];

        require(ownerOf[id] != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            totalSupply--;

            balanceOf[owner]--;
        }

        delete ownerOf[id];

        emit Transfer(owner, address(0), id);
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
interface ERC721TokenReceiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 id,
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

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
        return a > b ? a : b;
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
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

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
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

import { IDittoPool } from "../interface/IDittoPool.sol";

/**
 * @notice Basic Struct used by DittoRouter For Specifying trades
 * @dev **pool** the pool to trade with
 * @dev **nftIds** which Nfts you wish to buy out of or sell into the pool
 */
struct Swap {
    IDittoPool pool;
    uint256[] nftIds;
    bytes swapData;
}

/**
 * @notice Struct used by DittoRouter when selling Nfts into a pool.
 * @dev **swapInfo** Swap info with pool and and Nfts being traded
 * @dev **lpIds** The LP Position TokenIds of the counterparties you wish to sell to in the pool
 * @dev **permitterData** Optional: data to pass to the pool for permission checks that the tokenIds are allowed in the pool
 */
struct NftInSwap {
    IDittoPool pool;
    uint256[] nftIds;
    uint256[] lpIds;
    bytes permitterData;
    bytes swapData;
}

/**
 * @notice Struct used for "robust" swaps that may have partial fills buying NFTs out of a pool
 * @dev **swapInfo** Swap info with pool and and Nfts being traded
 * @dev **maxCost** The maximum amount of tokens you are willing to pay for the Nfts total
 */
struct RobustSwap {
    IDittoPool pool;
    uint256[] nftIds;
    uint256 maxCost;
    bytes swapData;
}

/**
 * @notice Struct used for "robust" swaps that may have partial fills selling NFTs into a pool
 * @dev **nftSwapInfo** Swap info with pool, Nfts being traded, lp counterparties, and permitter data
 * @dev **minOutput** The total minimum amount of tokens you are willing to receive for the Nfts you sell, or abort
 */
struct RobustNftInSwap {
    IDittoPool pool;
    uint256[] nftIds;
    uint256[] lpIds;
    bytes permitterData;
    uint256 minOutput;
    bytes swapData;
}

/**
 * @notice DittoRouter struct for complex swaps with tokens bought and sold in one transaction
 * @dev **nftToTokenTrades** array of trade info where you are selling Nfts into pools
 * @dev **tokenToNftTrades** array of trade info where you are buying Nfts out of pools
 */
struct ComplexSwap {
    NftInSwap[] nftToTokenTrades;
    Swap[] tokenToNftTrades;
}

/**
 * @notice DittoRouter struct for robust partially-fillable complex swaps with tokens bought and sold in one transaction
 * @dev **nftToTokenTrades** array of trade info where you are selling Nfts into pools
 * @dev **tokenToNftTrades** array of trade info where you are buying Nfts out of pools
 * @dev **inputAmount** The total amount of tokens you are willing to spend on the Nfts you buy
 * @dev **tokenRecipient** The address to send the tokens to after the swap
 * @dev **nftRecipient** The address to send the Nfts to after the swap
 */
struct RobustComplexSwap {
    RobustSwap[] tokenToNftTrades;
    RobustNftInSwap[] nftToTokenTrades;
    uint256 inputAmount;
    address tokenRecipient;
    address nftRecipient;
    uint256 deadline;
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity 0.8.19;

/**
 * @title IERC4906
 * @notice Copied from https://github.com/ethereum/EIPs/blob/master/EIPS/eip-4906.md
 */
interface IERC4906 {
    /// @dev This event emits when the metadata of a token is changed.
    /// So that the third-party platforms such as NFT market could
    /// timely update the images and related attributes of the NFT.
    event MetadataUpdate(uint256 _tokenId);

    /// @dev This event emits when the metadata of a range of tokens is changed.
    /// So that the third-party platforms such as NFT market could
    /// timely update the images and related attributes of the NFTs.
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

/**
 * @title IPoolManager
 * @notice Interface for the PoolManager contract
 */
interface IPoolManager {
    /**
     * @notice Initializes the permitter contract with some initial state.
     * @param dittoPool_ the address of the DittoPool that this manager is managing.
     * @param data_ any data necessary for initializing the permitter.
     */
    function initialize(address dittoPool_, bytes memory data_) external;

    /**
     * @notice Returns whether or not the contract has been initialized.
     * @return initialized Whether or not the contract has been initialized.
     */
    function initialized() external view returns (bool);

    /**
     * @notice Change the base price charged to buy an NFT from the pair
     * @param newBasePrice_ New base price: now NFTs purchased at this price, sold at `newBasePrice_ + Delta`
     */
    function changeBasePrice(uint128 newBasePrice_) external;

    /**
     * @notice Change the delta parameter associated with the bonding curve
     * @dev see the bonding curve documentation on bonding curves for additional information
     * Each bonding curve uses delta differently, but in general it is used as an input
     * to determine the next price on the bonding curve
     * @param newDelta_ New delta parameter
     */
    function changeDelta(uint128 newDelta_) external;

    /**
     * @notice Change the pool lp fee, set by owner, paid to LPers only when they are the counterparty in a trade
     * @param newFeeLp_ New fee, in wei / 1e18, charged by the pool for trades with it (i.e. 1% = 0.01e18)
     */
    function changeLpFee(uint96 newFeeLp_) external;

    /**
     * @notice Change the pool admin fee, set by owner, paid to admin (or whoever they want)
     * @param newFeeAdmin_ New fee, in wei / 1e18, charged by the pool for trades with it (i.e. 1% = 0.01e18)
     */
    function changeAdminFee(uint96 newFeeAdmin_) external;

    /**
     * @notice Change who the pool admin fee for this pool is sent to.
     * @param newAdminFeeRecipient_ New address to send admin fees to.
     */
    function changeAdminFeeRecipient(address newAdminFeeRecipient_) external;

    /**
     * @notice Change the owner of the underlying DittoPool, functions independently of PoolManager
     *   ownership transfer.
     * @param newOwner_ The new owner of the underlying DittoPool
     */
    function transferPoolOwnership(address newOwner_) external;
}