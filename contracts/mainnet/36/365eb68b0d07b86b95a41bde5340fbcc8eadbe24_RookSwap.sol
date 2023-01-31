// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "./reentrancyGuard.sol";
import "./whitelist.sol";
import "./owner.sol";
import "./assetManagement.sol";
import "./orderUtils.sol";
import "./utils.sol";

/**
 * @title RookSwap - A token swapping protocol that enables users to receive MEV generated from their orders.
 * A keeper executes the order on behalf of the user and extracts the value created by the order to distribute back to the user.
 * Orders are signed and submitted to an off-chain orderbook, where keepers can bid for the right to execute.
 * Users don't have to pay gas to swap tokens, except for token allowance approvals.
 * @author Joey Zacherl - <[email protected]>

 * Note: Some critical public/external functions in this contract are appended with underscores and extra characters as a gas optimization
 * Example: function() may become function_xyz() or function__abc()
 */

// Exception codes
// RS:E0 - ETH transfer failed
// RS:E1 - Address(0) is not allowed
// RS:E2 - Cannot overfill order
// RS:E3 - Order not partially fillable, must fill order exactly full
// RS:E4 - Order already filled
// RS:E5 - Swap tokens must differ
// RS:E6 - Order not fillable
// RS:E7 - Order signature invalid
// RS:E8 - Malformed ecdsa signature
// RS:E9 - Invalid ecdsa signature
// RS:E10 - Malformed pre-signature
// RS:E11 - toUint256_outOfBounds
// RS:E12 - Array lengths must match, orders and makerAmountsToSpend
// RS:E13 - Do not use takerTokenDistribution_custom for one single order, use takerTokenDistribution_even
// RS:E14 - Array lengths must match, orders and takerTokenDistributions
// RS:E15 - Orders must not involve the same maker & same tokens
// RS:E16 - Presigner must be valid
// RS:E17 - Must be owner
// RS:E18 - ReentrancyGuard: reentrant call
// RS:E19 - Can not approve allowance for 0x0
// RS:E20 - Not permitted to cancel order
// RS:E21 - Must be whitelisted Keeper
// RS:E22 - Must be whitelisted DexAggKeeper
// RS:E23 - maker not satisfied, partiallyFillable = true
// RS:E24 - maker not satisfied, partiallyFillable = false
// RS:E25 - RookSwap contract surplusToken balances must not decrease, including threshold
// RS:E26 - RookSwap contract otherToken balances must not decrease
// RS:E27 - Begin and expiry must be valid
// RS:E28 - surplusToken must be in all orders
// RS:E29 - otherToken must be in all orders
// RS:E30 - Must be whitelisted DexAggRouter
// RS:E31 - surplusToken and otherToken must differ
// RS:E32 - approveToken must be either surplusToken or otherToken

/**
 * @dev Keeper interface for the callback function to execute swaps.
 */
abstract contract Keeper
{
    function rookSwapExecution_s3gN(
        address rookSwapsMsgSender,
        uint256[] calldata makerAmountsSentByRook,
        bytes calldata data
    )
        external
        virtual
        returns (bytes memory keeperReturn);
}

contract RookSwap is
    ReentrancyGuard,
    Owner,
    AssetManagement,
    Whitelist,
    OrderUtils
{
    using Address for address;
    using SafeERC20 for IERC20;
    using LibBytes for bytes;

    /**
     * @dev Facilitate swaps using Keeper's calldata through Keeper's custom trading contract.
     * Must be a whitelisted Keeper.
     * @param orders The orders to fill
     * @param makerAmountsToSpend makerAmounts to fill, correspond with orders
     * @param keeperTaker Keeper's taker address which will execute the swap, typically a trading contract. Must implement rookSwapExecution_s3gN.
     * @param data Keeper's calldata to pass into their rookSwapExecution_s3gN implementation.
     * This calldata is responsible for facilitating trade and paying the maker back in
     * takerTokens, or else the transaction will revert.
     * @return keeperReturn Return the Keeper's keeperCallData return value from rookSwapExecution_s3gN.
     * They'll likey want this for simulations, it's up to the Keeper to decide what to return
     * to help with tx simulations.
     */
    function swapKeeper__oASr(
        Order[] calldata orders,
        uint256[] calldata makerAmountsToSpend,
        address keeperTaker,
        bytes calldata data
    )
        external
        nonReentrant
        returns (bytes memory keeperReturn)
    {
        // Only allow swap execution whitelisted Keepers
        require(
            getKeeperWhitelistPosition__2u3w(keeperTaker) != 0,
            "RS:E21"
        );

        LibData.MakerData[] memory makerData = _prepareSwapExecution(orders, makerAmountsToSpend, keeperTaker);

        // Call the keeper's rookSwapExecution_s3gN function to execute the swap
        // Keeper must satisfy the user based on the signed order within this callback execution
        // We are passing in msg.sender to the keeper's rookSwapExecution_s3gN function.
        // We have ensured that keeperTaker is a whitelisted Rook keeper
        // but we have not ensured that msg.sender is keeperTaker's EOA
        // Keeper is responsible for ensuring that the msg.sender we pass them is their EOA and in their personal whitelist
        // Keeper is also responsible for ensuring that only a valid RookSwap contract can call their rookSwapExecution_s3gN function
        // This RookSwap contract is NOT upgradeable, so you can trust that the msg.sender we're passing along to Keeper is safe and correct
        keeperReturn = Keeper(keeperTaker).rookSwapExecution_s3gN(msg.sender, makerAmountsToSpend, data);

        _finalizeSwapExecution(orders, makerAmountsToSpend, makerData, keeperTaker);
    }

    /**
     * @dev Facilitate swaps using DexAgg Keeper's calldata through this contract.
     * Must be a whitelisted DexAgg Keeper.
     * @param orders The orders to fill.
     * @param makerAmountsToSpend makerAmounts to fill, correspond with orders.
     * @param makerWeights Mathematical weight for distributing tokens to makers.
     * moved this math off chain to save gas and simplify on chain computation.
     * corresponds with orders.
     * @param swap Execution calldata for facilitating a swap via DEX Aggregators right here on this contract.
     * If this function fails to pay back the maker in takerTokens, the transaction will revert.
     * @param takerTokenDistributions Quantities for distributing tokens to makers.
     * moved this math off chain to save gas and simplify on chain computation.
     * corresponds with orders.
     * @param metaData Supplementary data for swap execution and how to handle surplusTokens.
     * @return surplusAmount Amount of surplusTokens acquired during swap execution.
     */
    function swapDexAggKeeper_8B77(
        Order[] calldata orders,
        uint256[] calldata makerAmountsToSpend,
        uint256[] calldata makerWeights,
        LibSwap.DexAggSwap calldata swap,
        uint256[] calldata takerTokenDistributions,
        LibSwap.MetaData calldata metaData
    )
        external
        nonReentrant
        returns (uint256 surplusAmount)
    {
        // Only allow swap execution whitelisted DexAggKeepers
        require(
            getDexAggKeeperWhitelistPosition_IkFc(msg.sender) != 0,
            "RS:E22"
        );

        // Only allow swap execution on whitelisted DexAggs
        require(
            getDexAggRouterWhitelistPosition_ZgLC(swap.router) != 0,
            "RS:E30"
        );

        // surplusToken and otherToken must differ
        require(
            metaData.surplusToken != metaData.otherToken,
            "RS:E31"
        );

        // surplusToken and otherToken must be in every order, meaning there can only be 2 unique tokens in the swap.
        // otherwise this is an unsupported type of batching, or there is a logic bug with the dexAggKeeper offchain logic.
        // This check may not be necessary, but it's good to reject types of batching that are not supported today.
        // Reverting here will help prevent bugs and undesired behaviors.
        for (uint256 i; i < orders.length;)
        {
            require(
                metaData.surplusToken == orders[i].makerToken || metaData.surplusToken == orders[i].takerToken,
                "RS:E28"
            );
            require(
                metaData.otherToken == orders[i].takerToken || metaData.otherToken == orders[i].makerToken,
                "RS:E29"
            );

            // Gas optimization
            unchecked
            {
                ++i;
            }
        }

        LibData.ContractData memory contractData = LibData.ContractData(
            IERC20(metaData.surplusToken).balanceOf(address(this)),
            0,
            IERC20(metaData.otherToken).balanceOf(address(this))
        );
        LibData.MakerData[] memory makerData = _prepareSwapExecution(orders, makerAmountsToSpend, address(this));

        // Begin the swap execution by performing swaps on DexAggs
        uint256 takerTokenAmountToDistribute = _beginDexAggSwapExecution(
            swap,
            metaData
        );

        // Complete the swap execution by distributing takerTokens properly
        if (metaData.takerTokenDistributionType == LibSwap.TakerTokenDistributionType.Even)
        {
            _completeDexAggSwapExecution_takerTokenDistribution_even(
                orders,
                makerWeights,
                takerTokenAmountToDistribute
            );
        }
        else // elif (metaData.takerTokenDistributionType == LibSwap.TakerTokenDistributionType.Custom)
        {
            _completeDexAggSwapExecution_takerTokenDistribution_custom(
                orders,
                takerTokenDistributions
            );
        }

        _finalizeSwapExecution(orders, makerAmountsToSpend, makerData, msg.sender);

        // Return the amount of surplus retained
        surplusAmount = _finalizeSwapExecution_dexAggKeeper(contractData, metaData);
    }

    /**
     * @dev Prepare for swap execution by doing math, validating orders, and
     * transferring makerTokens from the maker to the Keeper which will be facilitating swaps.
     */
    function _prepareSwapExecution(
        Order[] calldata orders,
        uint256[] calldata makerAmountsToSpend,
        address makerTokenRecipient
    )
        private
        returns (LibData.MakerData[] memory makerData)
    {
        uint256 ordersLength = orders.length;
        require(
            ordersLength == makerAmountsToSpend.length,
            "RS:E12"
        );

        makerData = new LibData.MakerData[](ordersLength);
        for (uint256 i; i < ordersLength;)
        {
            // RookSwap does not currently support batching together swaps where 2 or more of the orders have the same maker & same tokens
            // This could be supported, however the gas efficiency would be horrible
            // because we'd have to use mappings and storage which costs a lot of gas
            // If you want to batch together orders in this way, it's still supported if you
            // by simply calling the RookSwap's swap function separately.
            // Example:
            //  call (RookSwap).swapKeeper([order1, order2, order3])
            //  then immediately after call (RookSwap).swapKeeper([order4, order5, order6])
            //  In this example let's assume that order1 and order4 include the same maker & tokens, so they had to be in separate function calls
            //  examples of order1 and order4
            //      Order1: Maker0x1234 swapping 900 DAI -> 0.6 WETH
            //      Order4: Maker0x1234 swapping 900 DAI -> 0.6 WETH
            // The reason for this is that _finalizeSwapExecution would be exposed to an exploit
            // if it attempted to process them in one single function call
            // And if we do process it securely in one signle function call, gas efficiency suffers beyond recovery.

            //  examples of order1 and order4
            //      Order1: Maker0x1234 swapping 0.6 WETH -> 900 DAI
            //      Order4: Maker0x1234 swapping 900 DAI -> 0.6 WETH

            //  examples of order1 and order5
            //      Order1: Maker0x1234 swapping 0.6 WETH -> 900 DAI
            //      Order5: Maker0x1234 swapping 900 DAI -> 900 USDC

            for (uint256 j; j < ordersLength;)
            {
                if (i != j && orders[i].maker == orders[j].maker &&
                    (orders[i].takerToken == orders[j].takerToken || orders[i].makerToken == orders[j].takerToken))
                {
                    revert("RS:E15");
                }

                // Gas optimization
                unchecked
                {
                    ++j;
                }
            }

            bytes32 orderHash = getOrderHash(orders[i]);
            // makerData[i] = orders[i].data._decodeData(orderHash);
            makerData[i] = _decodeData(orders[i].data, orderHash);
            // Set the balance in the makerData
            makerData[i].takerTokenBalance_before = IERC20(orders[i].takerToken).balanceOf(orders[i].maker);

            // We are calling this with doGetActualFillableMakerAmount = false as a gas optimization
            // and with doRevertOnFailure = true because we expect it to revert if the order is not fillable
            // We don't care about making that extra gas consuming calls
            // The only reason we're calling this function, is to validate the order
            _validateAndGetOrderRelevantStatus(orders[i], orderHash, makerData[i], true, false);

            // Transfer makers makerToken to the keeper to begin trade execution
            IERC20(orders[i].makerToken).safeTransferFrom(orders[i].maker, makerTokenRecipient, makerAmountsToSpend[i]);

            // Update makerAmountFilled now that the makerTokens have been spent
            // The tx will revert if the maker isn't paid back takerTokens based on the order they signed
            _updateMakerAmountFilled(
                orders[i].makerAmount,
                orderHash,
                makerAmountsToSpend[i],
                makerData[i].partiallyFillable
            );

            // Gas optimization
            unchecked
            {
                ++i;
            }
        }
    }

    /**
     * @dev Begin executing swap for DexAgg Keeper by executing the swap's calldata on the DexAgg.
     * Also calculate the amount of tokens we need to distribute.
     */
    function _beginDexAggSwapExecution(
        LibSwap.DexAggSwap calldata swap,
        LibSwap.MetaData calldata metaData
    )
        private
        returns (uint256 takerTokenAmountToDistribute)
    {
        // Begin swap execution by executing the swap on the DexAgg
        takerTokenAmountToDistribute = _dexAggKeeperSwap(swap, metaData);

        if (metaData.surplusTokenIsSwapTakerToken)
        {
            // With regards to a custom takerToken distribution
            // SurplusAmount could be extracted both from the makerToken and takerToken of a batched swap
            // Example: from the makerToken of User1's swap and the takerToken of User2's swap.
            // In this case User1 and User2 are sharing the tx gas fee.
            // So in this case, surplusAmountWithheld is only a fraction of the entire tx gas fee
            // And that's okay because this logic doesn't care about the other fraction of the tx gas fee
            // that was extracted at the beginning of the tx

            // Deduct the txs gas fee from the takerTokenAmountToDistribute because it's the surplusToken
            takerTokenAmountToDistribute = takerTokenAmountToDistribute - metaData.surplusAmountWithheld;
        }
    }

    /**
     * @dev Complete DexAgg Keeper swap execution by distributing the takerTokens evenly among all makers in the batch.
     * This function supports on chain positive slippage by utilizing the makerWeights and some simple math.
     */
    function _completeDexAggSwapExecution_takerTokenDistribution_even(
        Order[] calldata orders,
        uint256[] calldata makerWeights,
        uint256 takerTokenAmountToDistribute
    )
        private
    {
        uint256 ordersLength = orders.length;
        // Transfer takerToken to maker to complete trade
        // If statement here because we can save gas by not doing math if there's only 1 order in the batch
        // Otherwise we have to spend some gas on calculating the positive slippage for each user
        if (ordersLength == 1)
        {
            IERC20(orders[0].takerToken).safeTransfer(orders[0].maker, takerTokenAmountToDistribute);
        }
        else
        {
            // Determine how much to transfer to each maker in the batch
            for (uint256 i; i < ordersLength;)
            {
                IERC20(orders[i].takerToken).safeTransfer(orders[i].maker, takerTokenAmountToDistribute * makerWeights[i] / 1000000000000000000);

                // Gas optimization
                unchecked
                {
                    ++i;
                }
            }
        }
    }

    /**
     * @dev Complete DexAgg Keeper swap execution by distributing the takerTokens customly among all makers in the batch.
     * This function does NOT support on chain positive slippage as the math is determined off chain ahead of time.
     */
    function _completeDexAggSwapExecution_takerTokenDistribution_custom(
        Order[] calldata orders,
        uint256[] calldata takerTokenDistributions
    )
        private
    {
        // For all of our takerTokenDistributions,
        // Transfer takerToken to maker to complete trade

        // This function should only be called with 2 or more orders
        // If only 1 order is being processed, use evenTakerTokenDistribution instead
        uint256 ordersLength = orders.length;
        require(
            ordersLength > 1,
            "RS:E13"
        );

        // for every order, we must have an takerTokenDistribution
        require(
            ordersLength == takerTokenDistributions.length,
            "RS:E14"
        );

        for (uint256 i; i < ordersLength;)
        {
            IERC20(orders[i].takerToken).safeTransfer(orders[i].maker, takerTokenDistributions[i]);

            // Gas optimization
            unchecked
            {
                ++i;
            }
        }
    }

    /**
     * @dev Finalize swap execution by doing some math, verifying that each maker got paid, and emitting events.
     */
    function _finalizeSwapExecution(
        Order[] calldata orders,
        uint256[] calldata makerAmountsToSpend,
        LibData.MakerData[] memory makerData,
        address taker
    )
        private
    {
        // Require that all of the maker's swaps have been satisfied based on the order they signed
        for (uint256 i; i < orders.length;)
        {
            // Measure maker's post-trade balance
            makerData[i].takerTokenBalance_after = IERC20(orders[i].takerToken).balanceOf(orders[i].maker);

            // Validate order requirements
            uint256 takerAmountFilled = makerData[i].takerTokenBalance_after - makerData[i].takerTokenBalance_before;

            // Ensure the fill meets the maker's signed requirement
            // Gas optimization
            // if takerAmountDecayRate is zero, we can save gas by not calling _calculateCurrentTakerAmountMin
            // otherwise we must perform some extra calculations to determine currentTakerAmountMin
            uint256 currentTakerAmountMin =
                orders[i].takerAmountDecayRate == 0 ?
                orders[i].takerAmountMin :
                _calculateCurrentTakerAmountMin(
                    orders[i].takerAmountMin,
                    orders[i].takerAmountDecayRate, makerData[i]
                );
            if (makerData[i].partiallyFillable)
            {
                // If the order is partiallyFillable, we have to slightly alter our math to support checking this properly
                // We must factor in the ratio of the makerAmount we're actually spending against the order's full makerAmount
                // This is because the _calculateCurrentTakerAmountMin is always in terms of the order's full amount
                // OPTIMIZATION: I could store this in a variable to make the code cleaner, but that costs more gas
                // So I'm in-lining all this math to save on gas
                require(
                    takerAmountFilled * orders[i].makerAmount >= currentTakerAmountMin * makerAmountsToSpend[i],
                    "RS:E23"
                );
            }
            else
            {
                require(
                    takerAmountFilled >= currentTakerAmountMin,
                    "RS:E24"
                );
            }

            // Log the fill event
            emit Fill(
                orders[i].maker,
                taker,
                orders[i].makerToken,
                orders[i].takerToken,
                makerAmountsToSpend[i],
                takerAmountFilled,
                makerData[i].orderHash
            );

            // Gas optimization
            unchecked
            {
                ++i;
            }
        }
    }

    /**
     * @dev Finalize swap execution for the DexAgg Keeper by ensuring that this contract didn't lose value
     * and that all thresholds were satisfied.
     */
    function _finalizeSwapExecution_dexAggKeeper(
        LibData.ContractData memory contractData,
        LibSwap.MetaData calldata metaData
    )
        private
        view
        returns (uint256 surplusAmount)
    {
        // Measure post-trade balances
        contractData.surplusTokenBalance_after = IERC20(metaData.surplusToken).balanceOf(address(this));
        // Gas optimization
        // not setting a variable here since we only use it once
        // contractData.otherTokenBalance_after = IERC20(metaData.otherToken).balanceOf(address(this));

        // Require that the DexAggKeeper has been satisfied
        // Revert if the DexAggKeeper has lost value in surplusTokens or otherTokens
        // We expect to gain surplus in surplusTokens by metaData.surplusProtectionThreshold to cover the cost of gas and other fees
        // But we do not expect otherToken to increase
        // This protection is required so that we don't need to trust the DexAggs's calldata nearly as much

        // surplusToken must increase based on metaData.surplusProtectionThreshold, and should never decrease
        require(
            contractData.surplusTokenBalance_after >= (contractData.surplusTokenBalance_before + metaData.surplusProtectionThreshold),
            "RS:E25"
        );

        // otherToken must at least break even
        // Typically this balance will not increase, break even is normal
        require(
            IERC20(metaData.otherToken).balanceOf(address(this)) >= contractData.otherTokenBalance_before,
            "RS:E26"
        );

        surplusAmount = contractData.surplusTokenBalance_after - contractData.surplusTokenBalance_before;
    }

    /**
     * @dev Calculate the order's current takerAmountMin at this point in time.
     * The takerAmountDecayRate behaves like a dutch auction, as the takerAmount decays over time down to the takerAmountMin.
     * Setting the takerAmountDecayRate to zero disables this decay feature and the swapping price remains static.
     * Ideally, if takerAmountDecayRate is zero you don't even have to call this function because it just returns takerAmountMin.
     */
    function _calculateCurrentTakerAmountMin(
        uint256 takerAmountMin,
        uint256 takerAmountDecayRate,
        LibData.MakerData memory makerData
    )
        private
        view
        returns (uint256 currentTakerAmountMin)
    {
        // Saving gas by not creating variables for these
        // Leaving commented out variables here to help with readability
        // uint256 elapsedTime = block.timestamp - makerData.begin;
        // uint256 totalTime = makerData.expiry - makerData.begin;
        // uint256 timestamp = block.timestamp >= makerData.begin ? block.timestamp : makerData.begin;
        // uint256 multiplier  = block.timestamp < makerData.expiry ? makerData.expiry - timestamp: 0;
        // currentTakerAmountMin = takerAmountMin + (takerAmountDecayRate * multiplier);

        // Gas optimization
        // Saving gas by not creating variables for any of this.
        // The code is increidbly hard to read, but it saves a lot of gas
        // The more readable version of the code is commented out above
        currentTakerAmountMin =
            takerAmountMin + (takerAmountDecayRate * (
                block.timestamp < makerData.expiry
                    ?
                    makerData.expiry - (
                        block.timestamp >= makerData.begin
                            ?
                            block.timestamp
                            :
                            makerData.begin
                        )
                    :
                    0
                )
            );
    }

    /**
     * @dev Execute the swap calldatas on the DexAggs. Also manage allowances to the DexAggs.
     */
    function _dexAggKeeperSwap(
        LibSwap.DexAggSwap memory swap,
        LibSwap.MetaData calldata metaData
    )
        private
        returns (uint256 swapOutput)
    {
        // Execute all requried allowance approvals before swapping
        // We will assume that the function caller knows which tokens need approved and which do not
        // We should be approving the token we're spending inside the swap.callData, if we don't this tx will likely revert
        // So it's up to the function caller to set this properly or else reverts can happen due to no allowance
        require(
            swap.approveToken != address(0),
            "RS:E19"
        );

        // approveToken must be either surplusToken or otherToken, to prevent arbitrary token allowance approvals
        require(
            swap.approveToken == metaData.surplusToken || swap.approveToken == metaData.otherToken,
            "RS:E32"
        );

        // Approve exactly how much we intend to swap on the DexAgg
        IERC20(swap.approveToken).approve(swap.router, swap.approvalAmount);

        // Execute the calldata
        (bool success, bytes memory returnData) = swap.router.call{ value: 0 }(swap.callData);
        _verifyCallResult(success, returnData, "callData execution failed");
        swapOutput = returnData.toUint256(0);

        // Revoke the DexAgg's allowance now that the swap has finished
        IERC20(swap.approveToken).approve(swap.router, 0);
    }

    /**
     * @dev Verify the result of a call
     * This function reverts and bubbles up an error code if there's a problem
     * The return value doesn't matter, the function caller should already have the call's result
     */
    function _verifyCallResult(
        bool success,
        bytes memory returnData,
        string memory errorMessage
    )
        private
        pure
    {
        if (success)
        {
            // Nothing needs done, just return
            return;
        }
        else
        {
            // Look for revert reason and bubble it up if present
            if (returnData.length != 0)
            {
                // The easiest way to bubble the revert reason is using memory via assembly
                assembly
                {
                    let returnData_size := mload(returnData)
                    revert(add(32, returnData), returnData_size)
                }
            }
            else
            {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "./signing.sol";
import "./utils.sol";

contract OrderUtils is
    Signing
{
    /**
     * @dev Highest bit of a uint256, used to flag cancelled orders.
     */
    uint256 private constant HIGH_BIT = 1 << 255;

    /**
     * @dev Mapping from an orderHash to the filled amount in makerTokens
     * (paid by the maker) for that orderHash.
     */
    mapping(bytes32 => uint256) public makerAmountFilled;

    /**
     * @dev Order data containing a signed commitment a user made to swap tokens.
     */
    struct Order
    {
        // items contained within TYPEHASH_ORDER
        address maker;
        address makerToken;
        address takerToken;
        uint256 makerAmount;
        uint256 takerAmountMin;
        uint256 takerAmountDecayRate;
        uint256 data;
        // items NOT contained within TYPEHASH_ORDER
        bytes signature;
    }

    /**
     * @dev Status of an order depending on various events that play out.
     */
    enum OrderStatus
    {
        Invalid,
        Fillable,
        Filled,
        Canceled,
        Expired
    }
    /**
     * @dev Info about an order's status and general fillability.
     */
    struct OrderInfo
    {
        bytes32 orderHash;
        OrderStatus status;
        uint256 makerFilledAmount;
    }
    /**
     * @dev Event emitted when an order is filled.
     */
    event Fill(
        address maker,
        address taker,
        address makerToken,
        address takerToken,
        uint256 makerAmountFilled,
        uint256 takerAmountFilled,
        bytes32 orderHash
    );

    /**
     * @dev Event emitted when an order is canceled.
     */
    event OrderCancelled(
        bytes32 orderHash,
        address maker
    );

    constructor()
    {
    }

    /**
     * @dev Update the makerAmountFilled for the order being processed in a swap.
     */
    function _updateMakerAmountFilled(
        uint256 makerAmount,
        bytes32 orderHash,
        uint256 makerAmountToSpend,
        bool partiallyFillable
    )
        internal
    {
        // Update the fillAmount to prevent replay attacks
        // differentiate between partial fills and not allowing partial fills
        if (partiallyFillable)
        {
            uint256 newMakerAmountFilled = makerAmountFilled[orderHash] + makerAmountToSpend;
            // newMakerAmountFilled must be valid
            require(
                newMakerAmountFilled <= makerAmount,
                "RS:E2"
            );
            makerAmountFilled[orderHash] = newMakerAmountFilled;
        }
        else
        {
            // makerAmount must be valid
            require(
                makerAmountToSpend == makerAmount,
                "RS:E3"
            );
            // order must not already be filled
            require(
                makerAmountFilled[orderHash] == 0,
                "RS:E4"
            );
            // Since partial fills are not allowed, we must set this to the order's full amount
            makerAmountFilled[orderHash] = makerAmount;
        }
    }

    /**
     * @dev Get relevant order information to determine fillability of many orders.
     */
    function getOrderRelevantStatuses(
        Order[] calldata orders
    )
        external
        view
        returns (
            OrderInfo[] memory orderInfos,
            uint256[] memory makerAmountsFillable,
            bool[] memory isSignatureValids
        )
    {
        uint256 ordersLength = orders.length;
        orderInfos = new OrderInfo[](ordersLength);
        makerAmountsFillable = new uint256[](ordersLength);
        isSignatureValids = new bool[](ordersLength);
        for (uint256 i; i < ordersLength;)
        {
            // try/catches can only be used for external funciton calls
            try
                this.getOrderRelevantStatus(orders[i])
                    returns (
                        OrderInfo memory orderInfo,
                        uint256 makerAmountFillable,
                        bool isSignatureValid
                    )
            {
                orderInfos[i] = orderInfo;
                makerAmountsFillable[i] = makerAmountFillable;
                isSignatureValids[i] = isSignatureValid;
            }
            catch {}

            // Gas optimization
            unchecked
            {
                ++i;
            }
        }
    }

    /**
     * @dev Get relevant order information to determine fillability of an order.
     * This function must be public because it's being called in a try catch above.
     */
    function getOrderRelevantStatus(
        Order calldata order
    )
        external
        view
        returns (
            OrderInfo memory orderInfo,
            uint256 makerAmountFillable,
            bool isSignatureValid
        )
    {
        bytes32 orderHash = getOrderHash(order);
        LibData.MakerData memory makerData = _decodeData(order.data, orderHash);
        return _validateAndGetOrderRelevantStatus(order, orderHash, makerData, false, true);
    }

    /**
     * @dev Validate an order's signature and get relevant order information to determine fillability of an order.
     * Depending on what's calling this function, we may want to revert on a failure.
     * For example, if we are swapping and something bad happens
     *     we absolutely want to revert
     * But, if we are simply making an off chain call to check the order's status and we see a bad status
     *     we do NOT want to revert because this is critical information we want to return to the off chain function caller
     * Or we may want to provide additional data (or not, to save on gas cost).
     */
    function _validateAndGetOrderRelevantStatus(
        Order calldata order,
        bytes32 orderHash,
        LibData.MakerData memory makerData,
        bool doRevertOnFailure,
        bool doGetActualFillableMakerAmount
    )
        internal
        view
        returns (
            OrderInfo memory orderInfo,
            uint256 makerAmountFillable,
            bool isSignatureValid
        )
    {
        // Tokens must be different
        require(
            order.makerToken != order.takerToken,
            "RS:E5"
        );

        // Set the various parts of orderInfo
        orderInfo.orderHash = orderHash;
        orderInfo.makerFilledAmount = makerAmountFilled[orderInfo.orderHash];

        // Determine orderInfo.status
        // The high bit will be set if the order was cancelled
        if (orderInfo.makerFilledAmount & HIGH_BIT != 0)
        {
            orderInfo.status = OrderStatus.Canceled;
        }
        // If the order has already been filled to or over the max
        else if (orderInfo.makerFilledAmount >= order.makerAmount)
        {
            orderInfo.status = OrderStatus.Filled;
        }
        // Check for expiration
        else if (makerData.expiry <= block.timestamp)
        {
            orderInfo.status = OrderStatus.Expired;
        }
        else
        {
            // If we've made it this far, the order is fillable
            orderInfo.status = OrderStatus.Fillable;
        }

        // Validate order status
        // So I have this here that will revert if it's not fillable, but i don't think i'm verifying that it's filled properly.
        // For example, right now you can doulbe fill an order. I dont think there's anything stopping that
        require(
            !doRevertOnFailure || orderInfo.status == OrderStatus.Fillable,
            "RS:E6"
        );

        // Do not calculate makerAmountFillable internally when swapping,
        // only calculate it when making external calls checking the status of orders
        // This is critical because external parties care about this information
        // but when swapping tokens we do not, and not calling this saves a lot of gas
        // If when swapping tokens, the transaction were to fail because someone doesn't have an allowance,
        // we just let it fail and bubble up an exception elsewhere, this is a great gas optimization
        if (doGetActualFillableMakerAmount)
        {
            makerAmountFillable = _getMakerAmountFillable(order, orderInfo);
        }

        // Validate order signature against the signer
        address signer = _recoverOrderSignerFromOrderHash(orderInfo.orderHash, makerData.signingScheme, order.signature);

        // Order signer must be either the order's maker or the maker's valid signer
        // Gas optimization
        // We fist compare the order.maker and signer, before considering calling isValidOrderSigner()
        // isValidOrderSigner will read from storage which incurs a large gas cost
        isSignatureValid =
            signer != address(0) &&
            (
                (order.maker == signer) ||
                isValidOrderSigner(order.maker, signer)
            );

        require(
            !doRevertOnFailure || isSignatureValid,
            "RS:E7"
        );
    }

    /**
     * @dev Calculate the actual order fillability based on maker allowance, balances, etc
     */
    function _getMakerAmountFillable(
        Order calldata order,
        OrderInfo memory orderInfo
    )
        private
        view
        returns (uint256 makerAmountFillable)
    {
        if (orderInfo.status != OrderStatus.Fillable)
        {
            // Not fillable
            return 0;
        }
        if (order.makerAmount == 0)
        {
            // Empty order
            return 0;
        }

        // It is critical to have already returned above if the order is NOT fillable
        // because certain statuses like the canceled status modifies the makerFilledAmount value
        // which would mess up the below logic.
        // So we must not proceed with the below logic if any bits in makerFilledAmount
        // have been set by order cancels or something similiar

        // Get the fillable maker amount based on the order quantities and previously filled amount
        makerAmountFillable = order.makerAmount - orderInfo.makerFilledAmount;

        // Clamp it to the amount of maker tokens we can spend on behalf of the maker
        makerAmountFillable = Math.min(
            makerAmountFillable,
            _getSpendableERC20BalanceOf(IERC20(order.makerToken), order.maker)
        );
    }

    /**
     * @dev Get spendable balance considering allowance.
     */
    function _getSpendableERC20BalanceOf(
        IERC20 token,
        address owner
    )
        internal
        view
        returns (uint256 spendableERC20BalanceOf)
    {
        spendableERC20BalanceOf = Math.min(
            token.allowance(owner, address(this)),
            token.balanceOf(owner)
        );
    }

    /**
     * @dev Decode order data into its individual components.
     */
    function _decodeData(
        uint256 data,
        bytes32 orderHash
    )
        internal
        pure
        returns (LibData.MakerData memory makerData)
    {
        // Bits
        // 0 -> 63    = begin
        // 64 -> 127  = expiry
        // 128        = partiallyFillable
        // 129 -> 130 = signingScheme
        // 131 -> ... = reserved, must be zero

        uint256 begin = uint256(uint64(data));
        uint256 expiry = uint256(uint64(data >> 64));
        bool partiallyFillable = data & 0x100000000000000000000000000000000 != 0;
        // NOTE: Take advantage of the fact that Solidity will revert if the
        // following expression does not produce a valid enum value. This means
        // we check here that the leading reserved bits must be 0.
        LibSignatures.Scheme signingScheme = LibSignatures.Scheme(data >> 129);

        // Do not allow orders where begin comes after expiry
        // This doesn't make sense on a UI/UX level and leads to exceptions with our logic
        require(
            expiry >= begin,
            "RS:E27"
        );

        // Measure maker's pre-trade balance
        makerData = LibData.MakerData(
            orderHash,
            0,
            0,
            begin,
            expiry,
            partiallyFillable,
            signingScheme
        );
    }

    /**
     * @dev Cancel multiple orders. The caller must be the maker or a valid order signer.
     * Silently succeeds if the order has already been cancelled.
     */
    function cancelOrders__tYNw(
        Order[] calldata orders
    )
        external
    {
        for (uint256 i; i < orders.length;)
        {
            // Must be either the order's maker or the maker's valid signer
            if (orders[i].maker != msg.sender &&
                !isValidOrderSigner(orders[i].maker, msg.sender))
            {
                revert("RS:E20");
            }

            bytes32 orderHash = getOrderHash(orders[i]);
            // Set the high bit on the makerAmountFilled to indicate a cancel.
            // It's okay to cancel twice.
            makerAmountFilled[orderHash] |= HIGH_BIT;
            emit OrderCancelled(orderHash, orders[i].maker);

            // Gas optimization
            unchecked
            {
                ++i;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

contract Owner
{
    /**
     * @dev Current owner of this contract.
     */
    address owner;

    /**
     * @dev Pending owner of this contract. Set when an ownership transfer is initiated.
     */
    address pendingOwner;

    /**
     * @dev Event emitted when an ownership transfer is initiated.
     */
    event OwnershipTransferInitiated(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Event emmitted when ownership transfer has completed.
     */
    event OwnershipTransferCompleted(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor()
    {
        owner = msg.sender;
        emit OwnershipTransferCompleted(address(0), owner);
    }

    modifier onlyOwner()
    {
        require(
            owner == msg.sender,
            "RS:E17"
        );
        _;
    }

    /**
     * @dev Initiates ownership transfer by setting pendingOwner.
     */
    function transferOwnership(
        address newOwner
    )
        external
        onlyOwner
    {
        require(
            newOwner != address(0),
            "RS:E1"
        );

        pendingOwner = newOwner;
        emit OwnershipTransferInitiated(owner, newOwner);
    }

    /**
     * @dev Allows pendingOwner to claim ownership. 
     */
    function acceptOwnership(
    )
        external
    {
        require(
            pendingOwner == msg.sender,
            "RS:E17"
        );

        _transferOwnership(msg.sender);
    }

    /**
     * @dev Completes ownership transfer.
     */
    function _transferOwnership(
        address newOwner
    )
        internal
    {
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferCompleted(oldOwner, newOwner);
        delete pendingOwner;
    }
}

// SPDX-License-Identifier: MIT

// Vendored from OpenZeppelin contracts with minor modifications:
// - Modified Solidity version
// - Formatted code
// <https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.4.0/contracts/utils/ReentrancyGuard.sol>

pragma solidity 0.8.16;

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
abstract contract ReentrancyGuard
{
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

    constructor()
    {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant()
    {
        // On the first call to nonReentrant, _notEntered will be true
        require(
            _status != _ENTERED,
            "RS:E18"
        );

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "./owner.sol";

/**
 * @dev Type of whitelist
 */
enum WhitelistType
{
    Keeper,
    DexAggKeeper,
    DexAggRouter
}

/**
 * @dev Data specific to a particular whitelist
 */
struct WhitelistData
{
    // Array of whitelisted addresses
    address [] whitelistedAddressArray;
    // Keyed by whitelisted address, valued by position in whitelistedAddressArray
    mapping(address => uint256) whitelistedAddress;
}

/**
 * @dev Whitelist library containing logic resuable for all whitelists
 */
library LibWhitelist
{
    /**
     * @dev Event emitted when a new address has been whitelisted
     */
    event WhitelistEvent(
        address keeper,
        bool whitelisted,
        WhitelistType indexed whitelistType
    );

    /**
     * @dev Add addresses to the whitelist
     */
    function _addToWhitelist(
        WhitelistData storage whitelist,
        address[] memory addresses,
        WhitelistType whitelistType
    )
        internal
    {
        uint256 size = addresses.length;
        for (uint256 i = 0; i < size; i++)
        {
            address keeper = addresses[i];
            // Get the position of the address in the whitelist
            uint256 keeperPosition = whitelist.whitelistedAddress[keeper];

            // If it's currently whitelisted
            if (keeperPosition != 0)
            {
                // Skip it and emit the event again for reassurance
                emit WhitelistEvent(keeper, true, whitelistType);
                continue;
            }
            // Otherwise, it's not currently whitelisted
            // Get the position of the last whitelisted address
            uint256 position = whitelist.whitelistedAddressArray.length;
            // Store the new whitelisted address and position + 1 in the mapping and array
            whitelist.whitelistedAddress[keeper] = position + 1;
            whitelist.whitelistedAddressArray.push(keeper);

            emit WhitelistEvent(keeper, true, whitelistType);
        }
    }

    /**
     * @dev Remove addresses from the whitelist
     */
    function _removeFromWhitelist(
        WhitelistData storage whitelist,
        address[] memory addresses,
        WhitelistType whitelistType
    )
        internal
    {
        uint256 size = addresses.length;
        for (uint256 i = 0; i < size; i++)
        {
            address keeper = addresses[i];
            // Get the position of the address in the whitelist
            uint256 keeperPosition = whitelist.whitelistedAddress[keeper];

            // If it's not currently whitelisted
            if (keeperPosition == 0)
            {
                // Skip it and emit the event again for reassurance
                emit WhitelistEvent(keeper, false, whitelistType);
                continue;
            }
            // Otherwise, it's currently whitelisted
            // We need to remove the keeper from the array
            // We know that keeper is in the position keeperPosition
            // Get the length of the array
            uint256 lastKeeperPosition = whitelist.whitelistedAddressArray.length - 1;
            // Get the address stored in lastKeeperPosition
            address lastKeeper = whitelist.whitelistedAddressArray[lastKeeperPosition];

            // Set the new lastKeeperPosition
            // Remember that we store position increased by 1 in the mapping
            whitelist.whitelistedAddressArray[keeperPosition - 1] = whitelist.whitelistedAddressArray[lastKeeperPosition];

            // Update the mapping with the new position of the lastKeeper
            whitelist.whitelistedAddress[lastKeeper] = keeperPosition;
            // Update the mapping with zero as the new position of the removed keeper
            whitelist.whitelistedAddress[keeper] = 0;

            // Pop the last element of the array
            whitelist.whitelistedAddressArray.pop();

            emit WhitelistEvent(keeper, false, whitelistType);
        }
    }
}

/**
 * @dev Manages all whitelists on this contract
 */
contract Whitelist is Owner
{
    using LibWhitelist for WhitelistData;

    /**
     * @dev Whitelist for Keepers
     */
    WhitelistData keeperWhitelist;

    /**
     * @dev Whitelist for DexAgg Keepers
     */
    WhitelistData dexAggKeeperWhitelist;

    /**
     * @dev Whitelist for DexAgg Routers
     */
    WhitelistData dexAggRouterWhitelist;

    /**
     * @dev The address of the next whitelist in the link.
     */
    address public nextLinkedWhitelist;

    constructor()
    {
        // initialize as the null address, meaning this is the newest address in the chain
        nextLinkedWhitelist = address(0);
    }

    /**
     * @dev Set the next whitelist in the link
     */
    function setNextLinkedWhitelist(
        address newNextLinkedWhitelist
    )
        external
        onlyOwner
    {
        nextLinkedWhitelist = newNextLinkedWhitelist;
    }

    /**
     * @dev Get current keeper whitelist
     */
    function getKeeperWhitelist()
        public
        view
        returns (address[] memory)
    {
        return keeperWhitelist.whitelistedAddressArray;
    }

    /**
     * @dev Get current dex agg keeper whitelist
     */
    function getDexAggKeeperWhitelist()
        public
        view
        returns (address[] memory)
    {
        return dexAggKeeperWhitelist.whitelistedAddressArray;
    }

    /**
     * @dev Get current dex agg router whitelist
     */
    function getDexAggRouterWhitelist()
        public
        view
        returns (address[] memory)
    {
        return dexAggRouterWhitelist.whitelistedAddressArray;
    }

    /**
     * @dev Get the position of a given address in the whitelist.
     * If this address is not whitelisted, it will return a zero.
     */
    function getKeeperWhitelistPosition__2u3w(
        address keeper
    )
        public
        view
        returns (uint256 keeperWhitelistPosition)
    {
        keeperWhitelistPosition = keeperWhitelist.whitelistedAddress[keeper];
    }

    /**
     * @dev Get the position of a given address in the whitelist.
     * If this address is not whitelisted, it will return a zero.
     */
    function getDexAggKeeperWhitelistPosition_IkFc(
        address keeper
    )
        public
        view
        returns (uint256 dexAggKeeperWhitelistPosition)
    {
        dexAggKeeperWhitelistPosition = dexAggKeeperWhitelist.whitelistedAddress[keeper];
    }

    /**
     * @dev Get the position of a given address in the whitelist.
     * If this address is not whitelisted, it will return a zero.
     */
    function getDexAggRouterWhitelistPosition_ZgLC(
        address router
    )
        public
        view
        returns (uint256 dexAggRouterWhitelistPosition)
    {
        dexAggRouterWhitelistPosition = dexAggRouterWhitelist.whitelistedAddress[router];
    }

    /**
     * @dev Update the whitelist status of these addresses
     */
    function whitelistKeepers(
        address[] memory addresses,
        bool value
    )
        external
        onlyOwner
    {
        if (value)
        {
            keeperWhitelist._addToWhitelist(addresses, WhitelistType.Keeper);
        }
        else
        {
            keeperWhitelist._removeFromWhitelist(addresses, WhitelistType.Keeper);
        }
    }

    /**
     * @dev Update the whitelist status of these addresses
     */
    function whitelistDexAggKeepers(
        address[] memory addresses,
        bool value
    )
        external
        onlyOwner
    {
        if (value)
        {
            dexAggKeeperWhitelist._addToWhitelist(addresses, WhitelistType.DexAggKeeper);
        }
        else
        {
            dexAggKeeperWhitelist._removeFromWhitelist(addresses, WhitelistType.DexAggKeeper);
        }
    }

    /**
     * @dev Update the whitelist status of these addresses
     */
    function whitelistDexAggRouters(
        address[] memory addresses,
        bool value
    )
        external
        onlyOwner
    {
        if (value)
        {
            dexAggRouterWhitelist._addToWhitelist(addresses, WhitelistType.DexAggRouter);
        }
        else
        {
            dexAggRouterWhitelist._removeFromWhitelist(addresses, WhitelistType.DexAggRouter);
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./owner.sol";

contract AssetManagement is
    Owner
{
    using Address for address;
    using SafeERC20 for IERC20;

    /**
     * @dev Event emmitted when assets are withdrawn.
     */
    event Withdraw(
        address asset,
        uint256 amount
    );

    /**
     * @dev Withdraw Ether from this contract.
     */
	function withdrawEther_wEuX(
	    uint256 amount
    )
        external
        onlyOwner
    {
        (bool success, ) = msg.sender.call{value: amount}("");

        require(
            success,
            "RS:E0"
        );

        emit Withdraw(address(0), amount);
	}

    /**
     * @dev Withdraw tokens from this contract.
     */
	function withdrawToken_14u2(
	    address token,
        uint256 amount
    )
        external
        onlyOwner
    {
        require(
            token != address(0),
            "RS:E1"
        );

        IERC20(token).safeTransfer(msg.sender, amount);
        emit Withdraw(token, amount);
	}

    /**
     * @dev Manually set allowance for a given token & spender pair.
     * Allowances for this contract are managed via DexAggSwaps,
     * but any manual intervention is performed with this function.
     */
    function manuallySetAllowances(
        address spender,
        IERC20[] memory tokens,
        uint256[] memory values
    )
        external
        onlyOwner
    {
        require(
            spender != address(0),
            "RS:E1"
        );
        for (uint256 i; i < tokens.length;)
        {
            require(
                address(tokens[i]) != address(0),
                "RS:E1"
            );
            tokens[i].approve(spender, values[i]);

            // Gas optimization
            unchecked
            {
                ++i;
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library LibSignatures
{
    /**
     * @dev Enumeration of supported signing schemes
     */
    enum Scheme
    {
        Eip712,
        EthSign,
        Eip1271,
        PreSign
    }
}

library LibData
{
    /**
     * @dev Data specific to this contract.
     */
    struct ContractData
    {
        uint256 surplusTokenBalance_before;
        uint256 surplusTokenBalance_after;
        uint256 otherTokenBalance_before;
    }

    /**
     * @dev Data specific to a maker.
     */
    struct MakerData
    {
        // Params we calculate
        bytes32 orderHash;
        uint256 takerTokenBalance_before;
        uint256 takerTokenBalance_after;
        // Params extracted from order.data
        uint256 begin;
        uint256 expiry;
        bool partiallyFillable;
        LibSignatures.Scheme signingScheme;
    }
}

library LibSwap
{
    /**
     * @dev DexAgg swap calldata.
     */
    struct DexAggSwap
    {
        address router;
        bytes callData;
        address approveToken;
        uint256 approvalAmount;
    }

    /**
     * @dev Metadata regarding the swap and how to handle surplus
     */
    struct MetaData
    {
        address surplusToken;
        uint256 surplusAmountWithheld;
        address otherToken;
        bool surplusTokenIsSwapTakerToken;
        TakerTokenDistributionType takerTokenDistributionType;
        uint256 surplusProtectionThreshold;
    }

    /**
     * @dev How to handle swap takerToken distribution
     */
    enum TakerTokenDistributionType
    {
        Even,
        Custom
    }
}

library LibBytes
{
    /**
     * @dev Convert bytes to uint256
     */
    function toUint256(
        bytes memory bytesToConvert,
        uint256 start
    )
        internal
        pure
        returns (uint256 convertedInt)
    {
        require(
            bytesToConvert.length >= start + 32,
            "RS:E11"
        );
        assembly
        {
            convertedInt := mload(add(add(bytesToConvert, 0x20), start))
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.16;

import "./orderUtils.sol";
import "./eip1271.sol";
import "./utils.sol";

abstract contract Signing
{
    /**
     * @dev Name of contract.
     */
    string private constant CONTRACT_NAME = "Rook Swap";

    /**
     * @dev Version of contract.
     */
    string private constant CONTRACT_VERSION = "0.1.0";

    /**
     * @dev The EIP-712 typehash for the contract's domain.
     */
    bytes32 private constant TYPEHASH_DOMAIN = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /**
     * @dev The EIP-712 typehash for the Order struct.
     */
    bytes32 private constant TYPEHASH_ORDER = keccak256("Order(address maker,address makerToken,address takerToken,uint256 makerAmount,uint256 takerAmountMin,uint256 takerAmountDecayRate,uint256 data)");

    /**
     * @dev Storage indicating whether or not an orderHash has been pre signed
     */
    mapping(bytes32 => bool) public preSign;

    /**
     * @dev Event that is emitted when an account either pre-signs an order or revokes an existing pre-signature.
     */
    event PreSign(
        bytes32 orderHash,
        bool signed
    );

    /**
     * @dev The length of any signature from an externally owned account.
     */
    uint256 private constant ECDSA_SIGNATURE_LENGTH = 65;

    /**
     * @dev Domain separator.
     */
    bytes32 immutable domainSeparator;

    /**
     * @dev A mapping from a maker address to EOAs which are registered to sign on behalf of the maker address
     * The Maker address can be a smart contract or an EOA. This mapping enables EOAs to sign orders on behalf of
     * smart contracts or other EOAs.
     */
    mapping(address => mapping(address => bool)) orderSignerRegistry;

    /**
     * @dev Event emitted when a new signer is added (or modified) to orderSignerRegistry.
     */
    event OrderSignerRegistered(
        address maker,
        address signer,
        bool allowed
    );

    constructor()
    {
        domainSeparator = keccak256(
            abi.encode(
                TYPEHASH_DOMAIN,
                keccak256(bytes(CONTRACT_NAME)),
                keccak256(bytes(CONTRACT_VERSION)),
                _getChainId(),
                address(this)
            )
        );
    }

    /**
     * @dev Gets the chainId.
     */
    function _getChainId(
    )
        private
        view
        returns (uint256 chainId)
    {
        assembly
        {
            chainId := chainid()
        }
    }

    /**
     * @dev Calculates orderHash from Order struct
     */
    function getOrderHash(
        OrderUtils.Order calldata order
    )
        public
        view
        returns (bytes32 orderHash)
    {
        orderHash = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                keccak256(abi.encode(
                    TYPEHASH_ORDER,
                    order.maker,
                    order.makerToken,
                    order.takerToken,
                    order.makerAmount,
                    order.takerAmountMin,
                    order.takerAmountDecayRate,
                    order.data)
                )
            )
        );
    }

    /**
     * @dev Recovers an order's signer from the specified order and signature.
     * @param orderHash The orderHash to recover the signer for.
     * @param signingScheme The signing scheme (EIP-191, EIP-712, EIP-1271 or PreSign).
     * @param encodedSignature The signature bytes.
     * @return signer The recovered signer address from the specified signature,
     * or address(0) if signature is invalid (EIP-1271 and PreSign only).
     * We are not reverting if signer == address(0) in this function, that responsibility is on the function caller
     */
    function _recoverOrderSignerFromOrderHash(
        bytes32 orderHash,
        LibSignatures.Scheme signingScheme,
        bytes calldata encodedSignature
    )
        internal
        view
        returns (address signer)
    {
        if (signingScheme == LibSignatures.Scheme.Eip712)
        {
            signer = _ecdsaRecover(orderHash, encodedSignature);
        }
        else if (signingScheme == LibSignatures.Scheme.EthSign)
        {
            // The signed message is encoded as:
            // `"\x19Ethereum Signed Message:\n" || length || data`, where
            // the length is a constant (32 bytes) and the data is defined as:
            // `orderHash`.
            signer = _ecdsaRecover(
                keccak256(
                    abi.encodePacked(
                        "\x19Ethereum Signed Message:\n32",
                        orderHash
                    )
                ),
                encodedSignature);
        }
        else if (signingScheme == LibSignatures.Scheme.Eip1271)
        {
            // Use assembly to read the verifier address from the encoded
            // signature bytes.
            // solhint-disable-next-line no-inline-assembly
            assembly
            {
                // signer = address(encodedSignature[0:20])
                signer := shr(96, calldataload(encodedSignature.offset))
            }

            bytes calldata _signature = encodedSignature[20:];

            // Set signer to address(0) instead of reverting if isValidSignature fails.
            // We have to use a try/catch here in case the verifier's implementation of isValidSignature reverts when false
            // But we cannot rely only on that, because it may return a with a non 1271 magic number instead of reverting.
            try EIP1271Verifier(signer).isValidSignature(orderHash, _signature) returns (bytes4 magicValue)
            {
                // Check if isValidSignature return matches the 1271 magic value spec
                bool isValid = (magicValue == LibERC1271.MAGICVALUE);

                // If not, set signer to address(0)
                assembly
                {
                    let mask := mul(isValid, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
                    signer := and(signer, mask)
                }
            }
            catch
            {
                signer = address(0);
            }
        }
        else // signingScheme == Scheme.PreSign
        {
            assembly
            {
                // signer = address(encodedSignature[0:20])
                signer := shr(96, calldataload(encodedSignature.offset))
            }

            bool isValid = preSign[orderHash];

            assembly
            {
                let mask := mul(isValid, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
                signer := and(signer, mask)
            }
        }
        return signer;
    }

    /**
     * @dev Perform an ECDSA recover for the specified message and calldata
     * signature.
     * The signature is encoded by tighyly packing the following struct:
     * ```
     * struct EncodedSignature {
     *     bytes32 r;
     *     bytes32 s;
     *     uint8 v;
     * }
     * ```
     * @param message The signed message.
     * @param encodedSignature The encoded signature.
     * @return signer The recovered address from the specified signature.
     */
    function _ecdsaRecover(
        bytes32 message,
        bytes calldata encodedSignature
    )
        internal
        pure
        returns (address signer)
    {
        require(
            encodedSignature.length == ECDSA_SIGNATURE_LENGTH,
            "RS:E8"
        );

        bytes32 r;
        bytes32 s;
        uint8 v;

        // NOTE: Use assembly to efficiently decode signature data.
        // solhint-disable-next-line no-inline-assembly
        assembly
        {
            // r = uint256(encodedSignature[0:32])
            r := calldataload(encodedSignature.offset)
            // s = uint256(encodedSignature[32:64])
            s := calldataload(add(encodedSignature.offset, 32))
            // v = uint8(encodedSignature[64])
            v := shr(248, calldataload(add(encodedSignature.offset, 64)))
        }

        signer = ecrecover(message, v, r, s);
    }

    /**
     * @dev Sets presign signatures for a batch of specified orders.
     * @param orders The order data of the orders to pre-sign.
     * @param signed Boolean indicating whether to pre-sign or cancel pre-signature.
     */
    function setPreSigns_weQh(
        OrderUtils.Order[] calldata orders,
        bool signed
    )
        external
    {
        for (uint256 i; i < orders.length;)
        {
            // Must be either the order's maker or the maker's valid signer
            require(
                (orders[i].maker == msg.sender) || isValidOrderSigner(orders[i].maker, msg.sender),
                "RS:E16"
            );

            bytes32 orderHash = getOrderHash(orders[i]);

            preSign[orderHash] = signed;
            emit PreSign(orderHash, signed);

            // Gas optimization
            unchecked
            {
                ++i;
            }
        }
    }

    /**
     * @dev Checks if a given address is registered to sign on behalf of a maker address.
     * @param maker The maker address encoded in an order (can be a contract).
     * @param signer The address that is providing a signature.
     */
    function isValidOrderSigner(
        address maker,
        address signer
    )
        public
        view
        returns (bool isValid)
    {
        isValid = orderSignerRegistry[maker][signer];
    }

    /**
     * @dev Register a signer to sign on behalf of msg.sender (msg.sender can be a contract or EOA).
     * @param signer The address from which you plan to generate signatures.
     * @param allowed True to register, false to unregister.
     */
    function registerAllowedOrderSigner(
        address signer,
        bool allowed
    )
        external
    {
        require(
            signer != address(0),
            "RS:E1"
        );

        orderSignerRegistry[msg.sender][signer] = allowed;

        emit OrderSignerRegistered(msg.sender, signer, allowed);
    }
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
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
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.16;

library LibERC1271
{
    /** 
     * @dev Value returned by a call to `isValidSignature` if the signature
     * was verified successfully. The value is defined in EIP-1271 as:
     * bytes4(keccak256("isValidSignature(bytes32,bytes)"))
     */
     bytes4 internal constant MAGICVALUE = 0x1626ba7e;
}

/** 
 * @title EIP1271 Interface
 * @dev Standardized interface for an implementation of smart contract
 * signatures as described in EIP-1271. The code that follows is identical to
 * the code in the standard with the exception of formatting and syntax
 * changes to adapt the code to our Solidity version.
 */
interface EIP1271Verifier
{
    /**
     * @dev Should return whether the signature provided is valid for the
     * provided data
     * @param _hash      Hash of the data to be signed
     * @param _signature Signature byte array associated with _data
     *
     * MUST return the bytes4 magic value 0x1626ba7e when function passes.
     * MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for
     * solc > 0.5)
     * MUST allow external calls
     */
    function isValidSignature(
        bytes32 _hash,
        bytes memory _signature
    )
        external
        view
        returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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