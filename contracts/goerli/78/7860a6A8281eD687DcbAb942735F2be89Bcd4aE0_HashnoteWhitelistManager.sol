// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.4;

import "../../lib/grappa/src/config/types.sol" as Grappa;
import "../../lib/grappa/src/core/engines/cross-margin/types.sol" as MarginEngine;

interface IMarginEngine {
    function grappa() external view returns (address);

    function optionToken() external view returns (address);

    function marginAccounts(
        address
    )
        external
        view
        returns (
            MarginEngine.Position[] memory shorts,
            MarginEngine.Position[] memory longs,
            Grappa.Balance[] memory collaterals
        );

    function execute(address account, Grappa.ActionArgs[] calldata actions) external;

    function batchExecute(Grappa.BatchExecute[] calldata batchActions) external;

    function previewMinCollateral(
        MarginEngine.Position[] memory shorts,
        MarginEngine.Position[] memory longs
    ) external view returns (Grappa.Balance[] memory);
}

interface IGrappa {
    function assets(uint8) external view returns (Grappa.AssetDetail memory);

    function assetIds(address) external view returns (uint8);

    function engineIds(address) external view returns (uint8);

    function oracleIds(address) external view returns (uint8);

    function getPayout(
        uint256 tokenId,
        uint64 amount
    ) external view returns (address engine, address collateral, uint256 payout);

    function getProductId(
        address oracle,
        address engine,
        address underlying,
        address strike,
        address collateral
    ) external view returns (uint40 id);

    function getDetailFromProductId(
        uint40 productId
    )
        external
        view
        returns (
            address oracle,
            address engine,
            address underlying,
            uint8 underlyingDecimals,
            address strike,
            uint8 strikeDecimals,
            address collateral,
            uint8 collateralDecimals
        );
}

interface IOptionToken {
    function balanceOf(address account, uint256 id) external view returns (uint256);

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

interface IOracle {
    /**
     * @notice  get spot price of _base, denominated in _quote.
     * @param _base base asset. for ETH/USD price, ETH is the base asset
     * @param _quote quote asset. for ETH/USD price, USD is the quote asset
     * @return price with 6 decimals
     */
    function getSpotPrice(address _base, address _quote) external view returns (uint256);

    /**
     * @dev get expiry price of underlying, denominated in strike asset.
     * @param _base base asset. for ETH/USD price, ETH is the base asset
     * @param _quote quote asset. for ETH/USD price, USD is the quote asset
     * @param _expiry expiry timestamp
     *
     * @return price with 6 decimals
     */
    function getPriceAtExpiry(
        address _base,
        address _quote,
        uint256 _expiry
    ) external view returns (uint256 price, bool isFinalized);

    /**
     * @dev return the maximum dispute period for the oracle
     * @dev this will only be checked during oracle registration, as a soft constraint on integrating oracles.
     */
    function maxDisputePeriod() external view returns (uint256 disputePeriod);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./enums.sol";

/**
 * @dev struct representing the current balance for a given collateral
 * @param collateralId grappa asset id
 * @param amount amount the asset
 */
struct Balance {
    uint8 collateralId;
    uint80 amount;
}

/**
 * @dev struct containing assets detail for an product
 * @param underlying    underlying address
 * @param strike        strike address
 * @param collateral    collateral address
 * @param collateralDecimals collateral asset decimals
 */
struct ProductDetails {
    address oracle;
    uint8 oracleId;
    address engine;
    uint8 engineId;
    address underlying;
    uint8 underlyingId;
    uint8 underlyingDecimals;
    address strike;
    uint8 strikeId;
    uint8 strikeDecimals;
    address collateral;
    uint8 collateralId;
    uint8 collateralDecimals;
}

// todo: update doc
struct ActionArgs {
    ActionType action;
    bytes data;
}

struct BatchExecute {
    address subAccount;
    ActionArgs[] actions;
}

/**
 * @dev asset detail stored per asset id
 * @param addr address of the asset
 * @param decimals token decimals
 */
struct AssetDetail {
    address addr;
    uint8 decimals;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../../config/enums.sol";
import "../../../config/types.sol";

/**
 * @dev base unit of cross margin account. This is the data stored in the state
 *      storage packing is utilized to save gas.
 * @param shorts an array of short positions
 * @param longs an array of long positions
 * @param collaterals an array of collateral balances
 */
struct CrossMarginAccount {
    PositionOptim[] shorts;
    PositionOptim[] longs;
    Balance[] collaterals;
}

/**
 * @dev struct used in memory to represent a cross margin account's option set
 *      this is a grouping of like underlying, collateral, strike (asset), and expiry
 *      used to calculate margin requirements
 * @param putWeights            amount of put options held in account (shorts and longs)
 * @param putStrikes            strikes of put options held in account (shorts and longs)
 * @param callWeights           amount of call options held in account (shorts and longs)
 * @param callStrikes           strikes of call options held in account (shorts and longs)
 * @param underlyingId          grappa id for underlying asset
 * @param underlyingDecimals    decimal points of underlying asset
 * @param numeraireId           grappa id for numeraire (aka strike) asset
 * @param numeraireDecimals     decimal points of numeraire (aka strike) asset
 * @param spotPrice             current spot price of underlying in terms of strike asset
 * @param expiry                expiry of the option
 */
struct CrossMarginDetail {
    int256[] putWeights;
    uint256[] putStrikes;
    int256[] callWeights;
    uint256[] callStrikes;
    uint8 underlyingId;
    uint8 underlyingDecimals;
    uint8 numeraireId;
    uint8 numeraireDecimals;
    uint256 spotPrice;
    uint256 expiry;
}

/**
 * @dev a compressed Position struct, compresses tokenId to save storage space
 * @param tokenId option token
 * @param amount number option tokens
 */
struct PositionOptim {
    uint192 tokenId;
    uint64 amount;
}

/**
 * @dev an uncompressed Position struct, expanding tokenId to uint256
 * @param tokenId grappa option token id
 * @param amount number option tokens
 */
struct Position {
    uint256 tokenId;
    uint64 amount;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

enum TokenType {
    PUT,
    PUT_SPREAD,
    CALL,
    CALL_SPREAD
}

/**
 * @dev action types
 */
enum ActionType {
    AddCollateral,
    RemoveCollateral,
    MintShort,
    BurnShort,
    MergeOptionToken,
    SplitOptionToken,
    AddLong,
    RemoveLong,
    SettleAccount,
    // actions that influece more than one subAccounts:
    MintShortIntoAccount, // increase short (debt) position in one subAccount, increase long token directly to another subAccount
    TransferCollateral, // transfer collateral direclty to another subAccount
    TransferLong, // transfer long directly to another subAccount
    TransferShort // transfer short directly to another subAccount
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.4;

import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { FixedPointMathLib } from "solmate/src/utils/FixedPointMathLib.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { TokenIdUtil } from "../../lib/grappa/src/libraries/TokenIdUtil.sol";
import { ProductIdUtil } from "../../lib/grappa/src/libraries/ProductIdUtil.sol";
import { ActionUtil } from "../../lib/grappa/src/libraries/ActionUtil.sol";
import { AccountUtil } from "../../lib/grappa/src/core/engines/cross-margin/AccountUtil.sol";
import { TokenType, ActionType } from "../../lib/grappa/src/config/enums.sol";

import { Vault } from "./Vault.sol";
import { ShareMath } from "./ShareMath.sol";
import { SupportsNonCompliantERC20 } from "./SupportsNonCompliantERC20.sol";
import { IERC20Detailed } from "../interfaces/IERC20Detailed.sol";
import { IBatchAuction } from "../interfaces/IBatchAuction.sol";
import { IWhitelist } from "../interfaces/IWhitelist.sol";
import "../interfaces/GrappaInterfaces.sol";
import "../utils/Error.sol";

import "hardhat/console.sol";

library VaultLifecycle {
    using AccountUtil for MarginEngine.Position[];
    using ActionUtil for Grappa.ActionArgs[];
    using ActionUtil for Grappa.BatchExecute[];
    using FixedPointMathLib for uint256;
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using SupportsNonCompliantERC20 for IERC20;
    using SupportsNonCompliantERC20 for IERC20Detailed;
    using TokenIdUtil for uint256;
    using ProductIdUtil for uint40;

    event CreatedAuction(
        uint256[] indexed optionTokens,
        address indexed biddingToken,
        uint256 auctionId,
        address indexed manager
    );

    struct CloseParams {
        uint256 currentShareSupply;
        uint256 queuedWithdrawShares;
        uint256 managementFee;
        uint256 performanceFee;
        address feeRecipient;
        address oracleAddr;
        Vault.Collateral[] collaterals;
        uint256[] roundStartingBalances;
        uint256 expiry;
    }

    struct AuctionParams {
        address auctionAddr;
        address biddingToken;
        Vault.Collateral[] collaterals;
        uint256[] counterparty;
        uint256 duration;
        address engineAddr;
        uint256 maxStructures;
        uint256[] optionTokens;
        int256 premium;
        uint256 structures;
        address whitelist;
    }

    struct CreateStructuresParams {
        Vault.Collateral[] collaterals;
        uint256[] counterparty;
        address engineAddr;
        Vault.Instrument[] instruments;
        uint256[] optionTokens;
        uint256 structuresToMint;
        uint256 maxStructures;
        uint256[] vault;
    }

    /**
     * @notice Sets the next option the vault will be shorting, and calculates its premium for the auction
     * @param engineAddr is the address of the margin engine
     * @param strikePrices is the new strike prices
     * @param instruments is the linear combination of options
     * @param roundConfig the round configuration
     * @return tokenIds is the ids of the new options
     */
    function commitNextOption(
        address engineAddr,
        uint256[] calldata strikePrices,
        Vault.Instrument[] calldata instruments,
        Vault.RoundConfig storage roundConfig
    ) external view returns (uint256[] memory tokenIds, uint256 expiry) {
        if (strikePrices.length != instruments.length) revert VL_BadStrike();

        IMarginEngine engine = IMarginEngine(engineAddr);
        IGrappa grappa = IGrappa(engine.grappa());

        expiry = getNextExpiry(roundConfig);

        tokenIds = new uint256[](instruments.length);

        for (uint256 i = 0; i < instruments.length; i++) {
            uint40 productId = grappa.getProductId(
                instruments[i].oracle,
                engineAddr,
                instruments[i].underlying,
                instruments[i].strike,
                instruments[i].collateral
            );

            verifyProduct(productId, grappa, engine, instruments[i]);

            uint256 strikePrice = strikePrices[i];

            tokenIds[i] = TokenIdUtil.getTokenId(instruments[i].tokenType, productId, expiry, strikePrice, 0);
        }
    }

    /**
     * @notice Verify the productId has the correct parameters to prevent vulnerability to gamma contract changes
     * @param productId is the struct with details on previous option and strike selection details
     * @param grappa interface to grappa
     * @param marginEngine interface to margin engine
     * @param instrument is the struct with vault general data
     */
    function verifyProduct(
        uint40 productId,
        IGrappa grappa,
        IMarginEngine marginEngine,
        Vault.Instrument calldata instrument
    ) private view {
        if (address(grappa) == address(0)) revert VL_BadGrappaAddress();
        if (productId == 0) revert VL_BadProduct();

        (
            address oracle,
            address engine,
            address underlying,
            ,
            address strike,
            ,
            address collateral,
            uint8 collateralDecimals
        ) = grappa.getDetailFromProductId(productId);

        if (oracle != instrument.oracle) revert VL_BadOracleAddress();
        if (engine != address(marginEngine)) revert VL_BadGrappaAddress();
        if (underlying != instrument.underlying) revert VL_BadUnderlyingAddress();
        if (strike != instrument.strike) revert VL_BadStrikeAddress();
        if (collateral != instrument.collateral) revert VL_BadCollateralAddress();
        if (collateralDecimals != IERC20Detailed(collateral).decimals()) revert VL_BadPrecision();
    }

    /**
     * @notice Calculate the shares to mint, new price per share, and
      amount of funds to re-allocate as collateral for the new round
     * @param vaultState is the storage variable vaultState passed from HashnoteVault
     * @param params is the rollover parameters passed to compute the next state
     * @return currentBalances is the balances of the collateral at the start of the round
     * @return newPricePerShare is the price per share of the new round
     * @return mintShares is the amount of shares to mint from deposits
     * @return vaultFees is the amount of fees paid in each collateral
     */
    function closeRound(
        Vault.VaultState storage vaultState,
        CloseParams calldata params
    )
        external
        returns (
            uint256[] memory currentBalances,
            uint256 newPricePerShare,
            uint256 mintShares,
            uint256[] memory vaultFees
        )
    {
        // console.log("================================================closeRound");
        uint256 currentNAV;
        uint256 pendingNAV;

        (currentBalances, vaultFees) = processVaultFees(params, vaultState.totalPending);

        (currentNAV, pendingNAV) = _calculateNAV(vaultState, params);

        newPricePerShare = ShareMath.pricePerShare(params.currentShareSupply, currentNAV, pendingNAV);

        // After closing the short, if the options expire in-the-money
        // vault pricePerShare would go down because vault's asset balance decreased.
        // This ensures that the newly-minted shares do not take on the loss.
        mintShares = ShareMath.navToShares(pendingNAV, newPricePerShare);

        // console.log("closeRound currentShareSupply", params.currentShareSupply);
        // console.log("closeRound currentNAV", currentNAV);
        // console.log("closeRound totalVaultFee", totalVaultFee);
        // console.log("closeRound pendingNAV", pendingNAV);

        // console.log("closeRound newPricePerShare", newPricePerShare);
        // console.log("closeRound mintShares", mintShares);
    }

    function _calculateNAV(
        Vault.VaultState storage vaultState,
        CloseParams calldata params
    ) private view returns (uint256 currentNAV, uint256 pendingNAV) {
        (currentNAV) = calculateTotalBalanceNAV(params.oracleAddr, params.collaterals, params.expiry);

        pendingNAV = uint256(vaultState.totalPending);

        if (pendingNAV > 0)
            pendingNAV = calculateRelativeNAV(
                params.oracleAddr,
                params.collaterals,
                params.roundStartingBalances,
                pendingNAV,
                params.expiry
            );
    }

    /**
     * @notice Creates the actual Grappa short position by depositing collateral and minting optiontokens on behalf of Vault
     */
    function createStructures(CreateStructuresParams memory params) external {
        IMarginEngine engine = IMarginEngine(params.engineAddr);

        Grappa.ActionArgs[] memory vActions = _createMarginDepositActions(
            params.engineAddr,
            params.structuresToMint,
            params.maxStructures,
            params.collaterals,
            params.vault
        );

        Grappa.ActionArgs[] memory cpActions = _createMarginDepositActions(
            params.engineAddr,
            params.structuresToMint,
            params.maxStructures,
            params.collaterals,
            params.counterparty
        );

        address cpSubAccount = address(uint160(address(this)) ^ uint160(1));

        for (uint256 i; i < params.optionTokens.length; ) {
            Vault.Instrument memory instrument = params.instruments[i];
            uint256 tokenId = params.optionTokens[i];

            uint256 amount = params.structuresToMint.mulDivDown(toUint256(instrument.weight), Vault.UNIT);

            // console.log("createStructures amount", amount);

            // vault will receive all positive weighted instruments
            if (instrument.weight < 0)
                vActions = vActions.append(ActionUtil.createMintIntoAccountAction(tokenId, amount, cpSubAccount));
            else cpActions = cpActions.append(ActionUtil.createMintIntoAccountAction(tokenId, amount, address(this)));

            unchecked {
                ++i;
            }
        }

        Grappa.BatchExecute[] memory batch = new Grappa.BatchExecute[](1);
        batch[0] = Grappa.BatchExecute(address(this), vActions);

        if (cpActions.length > 0) batch = batch.append(Grappa.BatchExecute(cpSubAccount, cpActions));

        engine.batchExecute(batch);

        // (Grappa.Position[] memory shorts, , Grappa.Balance[] memory collaterals) = engine.marginAccounts(address(this));
        // console.log("createStructures shorts.length", shorts.length);
        // console.log("createStructures shorts[0].amount", shorts[0].amount);
        // console.log("createStructures collaterals.length", collaterals.length);
        // console.log("createStructures collaterals[0].amount", collaterals[0].amount);
    }

    function _createMarginDepositActions(
        address engineAddr,
        uint256 structuresToMint,
        uint256 maxStructures,
        Vault.Collateral[] memory collaterals,
        uint256[] memory balances
    ) private returns (Grappa.ActionArgs[] memory actions) {
        actions = new Grappa.ActionArgs[](balances.length);

        for (uint256 i; i < balances.length; ) {
            uint256 amount = structuresToMint.mulDivDown(balances[i], maxStructures);

            IERC20 collateral = IERC20(collaterals[i].addr);

            uint256 allowance = collateral.allowance(address(this), engineAddr);

            // console.log("_createMarginDepositActions structures", structuresToMint);
            // console.log("_createMarginDepositActions balances[i]", balances[i]);
            // console.log("_createMarginDepositActions pre-div", structuresToMint * balances[i]);
            // console.log("_createMarginDepositActions amount", amount);
            // console.log("_createMarginDepositActions address", collaterals[i].addr);
            // console.log("_createMarginDepositActions balance", collateral.balanceOf(address(this)));
            // console.log("_createMarginDepositActions new allowance", allowance + amount);

            // double approve to fix non-compliant ERC20s
            collateral.safeApproveNonCompliant(engineAddr, allowance + amount);

            actions[i] = ActionUtil.createAddCollateralAction(collaterals[i].id, amount, address(this));

            unchecked {
                ++i;
            }
        }
    }

    function novate(
        address engineAddr,
        Vault.Instrument[] memory instruments,
        uint256[] memory optionTokens,
        Vault.Collateral[] memory collaterals,
        uint256[] memory counterparty,
        address recipient,
        uint256 amount
    ) external {
        IMarginEngine engine = IMarginEngine(engineAddr);

        address cpSubAccount = address(uint160(address(this)) ^ uint160(1));

        Grappa.ActionArgs[] memory collateralTransfer = new Grappa.ActionArgs[](0);
        Grappa.ActionArgs[] memory longsTransfer = new Grappa.ActionArgs[](0);
        Grappa.ActionArgs[] memory shortsTransfer = new Grappa.ActionArgs[](0);

        for (uint256 i; i < counterparty.length; ) {
            uint256 collateralAmount = amount.mulDivDown(counterparty[i], Vault.UNIT);

            collateralTransfer = collateralTransfer.append(
                ActionUtil.createTransferCollateralAction(collaterals[i].id, collateralAmount, recipient)
            );

            unchecked {
                ++i;
            }
        }

        for (uint256 i; i < instruments.length; ) {
            Vault.Instrument memory instrument = instruments[i];
            uint256 tokenId = optionTokens[i];

            uint256 numOfOptions = amount.mulDivDown(toUint256(instrument.weight), Vault.UNIT);

            if (instrument.weight < 0)
                longsTransfer = longsTransfer.append(
                    ActionUtil.createTranferLongAction(tokenId, numOfOptions, recipient)
                );
            else
                shortsTransfer = shortsTransfer.append(
                    ActionUtil.createTranferShortAction(tokenId, numOfOptions, recipient)
                );

            unchecked {
                ++i;
            }
        }

        // console.log("novate collateralTransfer.length", collateralTransfer.length);
        // console.log("novate longsTransfer.length", longsTransfer.length);
        // console.log("novate shortsTransfer.length", shortsTransfer.length);

        Grappa.ActionArgs[] memory actions = new Grappa.ActionArgs[](0);

        // transfering shorts after collateral and longs to ensure account remains healthy
        if (collateralTransfer.length > 0) actions = actions.concat(collateralTransfer);
        if (longsTransfer.length > 0) actions = actions.concat(longsTransfer);
        if (shortsTransfer.length > 0) actions = actions.concat(shortsTransfer);

        if (actions.length > 0) engine.execute(cpSubAccount, actions);

        // Grappa.BatchExecute[] memory batch = new Grappa.BatchExecute[](0);
        // if (collateralTransfer.length > 0) batch = batch.append(Grappa.BatchExecute(cpSubAccount, collateralTransfer));
        // if (longsTransfer.length > 0) batch = batch.append(Grappa.BatchExecute(cpSubAccount, longsTransfer));
        // if (shortsTransfer.length > 0) batch = batch.append(Grappa.BatchExecute(cpSubAccount, shortsTransfer));
        // if (batch.length > 0) engine.batchExecute(batch);

        // if (collateralTransfer.length > 0) engine.execute(cpSubAccount, collateralTransfer);
        // if (longsTransfer.length > 0) engine.execute(cpSubAccount, longsTransfer);
        // // transfering shorts after collateral and longs to ensure account remains healthy
        // if (shortsTransfer.length > 0) engine.execute(cpSubAccount, shortsTransfer);
    }

    /**
     * @notice Close the existing short otoken position.
     * @param engineAddress is the address of the grappa margin engine contract
     */
    function settleOptions(address engineAddress) external {
        IMarginEngine engine = IMarginEngine(engineAddress);

        Grappa.ActionArgs[] memory actions = new Grappa.ActionArgs[](1);
        actions[0] = ActionUtil.createSettleAction();
        engine.execute(address(this), actions);

        (, , Grappa.Balance[] memory collaterals) = engine.marginAccounts(address(this));

        // console.log("collaterals.length", collaterals.length);
        // console.log("collaterals[0].amount", collaterals[0].amount);

        actions = new Grappa.ActionArgs[](collaterals.length);

        for (uint256 i; i < collaterals.length; ) {
            actions[i] = ActionUtil.createRemoveCollateralAction(
                collaterals[i].collateralId,
                collaterals[i].amount,
                address(this)
            );

            unchecked {
                ++i;
            }
        }

        engine.execute(address(this), actions);
    }

    function calculateTotalBalanceNAV(
        address oracleAddr,
        Vault.Collateral[] calldata collaterals,
        uint256 expiry
    ) public view returns (uint256 totalNAV) {
        // primary collateral addr, all other assets will be quotes in this
        address quote = collaterals[0].addr;

        // console.log("calculateTotalBalanceNAV quote", quote);

        for (uint256 i; i < collaterals.length; ) {
            uint256 price = _getPrice(oracleAddr, collaterals[i].addr, quote, expiry);

            uint256 balance = IERC20(collaterals[i].addr).balanceOf(address(this));

            uint256 value = price.mulDivDown(balance, 10 ** collaterals[i].decimals);

            // console.log("calculateTotalBalanceNAV base", collaterals[i].addr);
            // console.log("calculateTotalBalanceNAV price", price);
            // console.log("calculateTotalBalanceNAV balance", balances[i]);
            // console.log("calculateTotalBalanceNAV value", value);

            totalNAV += value;

            unchecked {
                ++i;
            }
        }

        // console.log("calculateTotalBalanceNAV totalNAV", totalNAV);
    }

    // calculates relative nav based on the primary asset (collaterals[0]) and current rounds starting balanaces
    function calculateRelativeNAV(
        address oracleAddr,
        Vault.Collateral[] calldata collaterals,
        uint256[] calldata roundStartingBalances,
        uint256 primaryNumerator,
        uint256 expiry
    ) public view returns (uint256 totalNAV) {
        // primary collateral addr, all other assets will be quotes in this
        address quote = collaterals[0].addr;

        uint256 primaryDenominator = roundStartingBalances[0];

        // console.log("calculateRelativeNAV primaryNumerator", primaryNumerator);
        // console.log("calculateRelativeNAV primaryDenominator", primaryDenominator);
        // console.log("calculateRelativeNAV quote", quote);

        for (uint256 i; i < collaterals.length; ) {
            uint256 price = _getPrice(oracleAddr, collaterals[i].addr, quote, expiry);

            uint256 balance = roundStartingBalances[i].mulDivDown(primaryNumerator, primaryDenominator);

            uint256 value = price.mulDivDown(balance, 10 ** collaterals[i].decimals);

            // console.log("calculateRelativeNAV base", collaterals[i].addr);
            // console.log("calculateRelativeNAV price", price);
            // console.log("calculateRelativeNAV roundStartingBalances", roundStartingBalances[i]);
            // console.log("calculateRelativeNAV balance", balance);
            // console.log("calculateRelativeNAV value", value);

            totalNAV += value;

            unchecked {
                ++i;
            }
        }

        // console.log("calculateRelativeNAV totalNAV", totalNAV);
    }

    function getCurrentBalances(
        Vault.Collateral[] calldata collaterals
    ) public view returns (uint256[] memory balances) {
        balances = new uint256[](collaterals.length);

        for (uint256 i; i < collaterals.length; ) {
            balances[i] = IERC20(collaterals[i].addr).balanceOf(address(this));

            unchecked {
                ++i;
            }
        }
    }

    function _getPrice(
        address oracleAddr,
        address base,
        address quote,
        uint256 expiry
    ) internal view returns (uint256 price) {
        IOracle oracle = IOracle(oracleAddr);

        // console.log("_getPrice expiry", expiry);

        if (expiry == Vault.PLACEHOLDER_UINT) price = oracle.getSpotPrice(base, quote);
        else (price, ) = oracle.getPriceAtExpiry(base, quote, expiry);
    }

    function transferCollaterals(
        uint256 primaryNumerator,
        Vault.Collateral[] calldata collaterals,
        uint256[] calldata roundStartingBalances,
        address recipient
    ) public returns (uint256[] memory amounts) {
        uint256 primaryDenominator = roundStartingBalances[0];

        bool isWithdraw = recipient != address(this);

        // console.log("transferCollaterals primaryNumerator", primaryNumerator);
        // console.log("transferCollaterals primaryDenominator", primaryDenominator);

        amounts = new uint256[](collaterals.length);

        for (uint256 i; i < collaterals.length; ) {
            uint256 balance = roundStartingBalances[i];

            if (isWithdraw) amounts[i] = balance.mulDivDown(primaryNumerator, primaryDenominator);
            else amounts[i] = balance.mulDivUp(primaryNumerator, primaryDenominator);

            // console.log("transferCollaterals collateral", collaterals[i].addr);
            // console.log("transferCollaterals balance", balance);
            // console.log("transferCollaterals amount", amount);
            // console.log("transferCollaterals recipient", recipient);
            // console.log("transferCollaterals withdraw", withdraw);

            if (amounts[i] > 0) {
                if (isWithdraw) IERC20(collaterals[i].addr).safeTransfer(recipient, amounts[i]);
                else IERC20(collaterals[i].addr).safeTransferFrom(msg.sender, recipient, amounts[i]);
            }

            unchecked {
                ++i;
            }
        }
    }

    function rebalance(
        address otc,
        uint256[] calldata amounts,
        Vault.Collateral[] calldata collaterals,
        uint256[] calldata vault,
        address whitelist
    ) external {
        if (collaterals.length != amounts.length) revert VL_DifferentLengths();

        if (!IWhitelist(whitelist).isOTC(otc)) revert VL_Unauthorized();

        for (uint256 i; i < collaterals.length; ) {
            if (amounts[i] > 0) {
                IERC20 asset = IERC20(collaterals[i].addr);

                uint256 surplus = asset.balanceOf(address(this)) - vault[i];

                if (amounts[i] > surplus) revert VL_ExceedsSurplus();

                asset.safeTransfer(otc, amounts[i]);
            }
            unchecked {
                ++i;
            }
        }
    }

    function withdrawCollateralsWithShares(
        uint256 shares,
        uint256 totalSupply,
        Vault.Collateral[] calldata collaterals
    ) external {
        // console.log("withdrawCollateralsWithShares shares", shares);
        // console.log("withdrawCollateralsWithShares totalSupply", totalSupply);

        for (uint256 i; i < collaterals.length; ) {
            uint256 balance = IERC20(collaterals[i].addr).balanceOf(address(this));

            // console.log("withdrawCollateralsWithShares asset", collaterals[i].addr);
            // console.log("withdrawCollateralsWithShares balance", balance);

            uint256 amount = balance.mulDivDown(shares, totalSupply);

            // console.log("withdrawCollateralsWithShares amount", amount);

            if (amount > 0) IERC20(collaterals[i].addr).safeTransfer(msg.sender, amount);

            // console.log(
            //     "withdrawCollateralsWithShares vault balance",
            //     IERC20(collaterals[i].addr).balanceOf(address(this))
            // );

            unchecked {
                ++i;
            }
        }
    }

    // function calculateNumberOfStructures(
    //     address engineAddress,
    //     Vault.Instrument[] storage instruments,
    //     uint256[] memory tokenIds,
    //     uint256 lockedAmount,
    //     address vaultCollateral,
    //     int256 premium,
    //     address premiumPaidIn
    // )
    //     external
    //     view
    //     returns (
    //         uint256 amount,
    //         uint256 vaultCollateralPerStructure,
    //         Grappa.Balance[] memory vault,
    //         Grappa.Balance[] memory counterparty
    //     )
    // {
    //     (vault, counterparty) = previewMinCollateral(engineAddress, tokenIds, instruments);

    //     IMarginEngine engine = IMarginEngine(engineAddress);
    //     IGrappa grappa = IGrappa(engine.grappa());

    //     for (uint256 i; i < vault.length; ) {
    //         Grappa.AssetDetail memory collateral = grappa.assets(vault[i].collateralId);

    //         uint256 denominator = vault[i].amount;
    //         uint256 decimals = collateral.decimals;
    //         uint256 balance;

    //         if (collateral.addr == vaultCollateral) {
    //             balance = lockedAmount;
    //             vaultCollateralPerStructure = denominator;
    //         } else balance = IERC20(collateral.addr).balanceOf(address(this));

    //         if (premiumPaidIn == collateral.addr && premium < 0) {
    //             uint256 scaledPremium = toUint256(premium);

    //             scaledPremium = decimals > 18
    //                 ? scaledPremium.mul(10**(decimals.sub(18)))
    //                 : scaledPremium.div(10**(uint256(18).sub(decimals)));

    //             denominator += scaledPremium;
    //         }

    //         uint256 newAmount = balance.mulDivDown(Vault.UNIT, denominator);

    //         if (i == 0 || amount > newAmount) amount = newAmount;

    //         unchecked {
    //             ++i;
    //         }
    //     }
    // }

    function previewMinCollateral(
        address engineAddress,
        uint256[] memory tokenIds,
        Vault.Instrument[] storage instruments,
        uint256 maxStructures
    ) public view returns (Grappa.Balance[] memory vault, Grappa.Balance[] memory counterparty) {
        IMarginEngine engine = IMarginEngine(engineAddress);

        MarginEngine.Position[] memory shorts = new MarginEngine.Position[](0);
        MarginEngine.Position[] memory longs = new MarginEngine.Position[](0);

        for (uint256 i; i < tokenIds.length; ) {
            Vault.Instrument memory instrument = instruments[i];

            uint256 tokenId = tokenIds[i];
            uint64 weight = instrument.weight < 0 ? uint64(-instrument.weight) : uint64(instrument.weight);
            uint256 amount = maxStructures.mulDivDown(Vault.UNIT, uint256(weight));

            // console.log("previewMinCollateral amount", amount);

            if (amount > type(uint64).max) revert VL_Overflow();

            if (instrument.weight < 0) shorts = shorts.append(MarginEngine.Position(tokenId, uint64(amount)));
            else longs = longs.append(MarginEngine.Position(tokenId, uint64(amount)));

            unchecked {
                ++i;
            }
        }

        // console.log("vault previewMinCollateral ============");
        vault = engine.previewMinCollateral(shorts, longs);

        // vaults longs are counterparty shorts, if the vault get 0 longs,
        // then no need to check counterparty collateral requirements
        if (longs.length > 0) {
            // console.log("counterparty previewMinCollateral ============");
            // vault longs are cp shorts and vault shorts are cp longs
            counterparty = engine.previewMinCollateral(longs, shorts);
        }
    }

    /**
     * @notice Calculates the performance and management fee for this week's round
     * @param params CloseParams passed to closeRound
     * @param currentBalances is the amount of funds currently held by vault
     * @param pendingAmount is the pending deposit amount
     * @return currentBalances is the collateral balances to start the round with
     * @return fees is the amounts paid in each collateral
     */
    function processVaultFees(
        CloseParams calldata params,
        uint256 pendingAmount
    ) public returns (uint256[] memory currentBalances, uint256[] memory fees) {
        currentBalances = getCurrentBalances(params.collaterals);

        fees = new uint256[](currentBalances.length);

        uint256 primaryNumerator = pendingAmount;
        uint256 primaryDenominator = params.roundStartingBalances[0];

        for (uint256 i; i < currentBalances.length; ) {
            uint256 lockedBalanceSansPending;
            uint256 managementFeeInAsset;
            uint256 performanceFeeInAsset;

            uint256 currentBalance = currentBalances[i];
            uint256 pendingBalance = params.roundStartingBalances[i].mulDivDown(primaryNumerator, primaryDenominator);

            // At the first round, currentBalance=0, pendingAmount>0
            // so we just do not charge anything on the first round
            if (currentBalance > pendingBalance) lockedBalanceSansPending = currentBalance.sub(pendingBalance);

            managementFeeInAsset = lockedBalanceSansPending.mulDivDown(
                params.managementFee,
                100 * Vault.FEE_MULTIPLIER
            );

            // Take performance fee ONLY if difference between
            // last round and this rounds's vault deposits, taking into account pending
            // deposits and withdrawals, is positive. If it is negative, last rounds's
            // option expired ITM past breakeven, and the vault took a loss so we
            // do not collect performance fee for last week.
            if (lockedBalanceSansPending > params.roundStartingBalances[i]) {
                if (params.performanceFee > 0) {
                    uint256 performanceAmount = lockedBalanceSansPending.sub(params.roundStartingBalances[i]);

                    performanceFeeInAsset = performanceAmount.mulDivDown(
                        params.performanceFee,
                        100 * Vault.FEE_MULTIPLIER
                    );
                }
            }

            fees[i] = managementFeeInAsset + performanceFeeInAsset;

            if (fees[i] > 0) {
                currentBalances[i] -= fees[i];

                IERC20(params.collaterals[i].addr).safeTransfer(params.feeRecipient, fees[i]);
            }

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Starts the Batch Auction
     * @param params is the struct with all the custom parameters of the auction
     * @return auctionId the auction id of the newly created auction
     */
    function startAuction(AuctionParams calldata params) external returns (uint256 auctionId) {
        if (params.structures > type(uint64).max) revert VL_Overflow();

        uint256 unsignedPremium = toUint256(params.premium);

        IERC20Detailed biddingToken = IERC20Detailed(params.biddingToken);

        int256 premium;

        {
            uint256 decimals = biddingToken.decimals();

            unsignedPremium = decimals > 18
                ? unsignedPremium.mul(10 ** (decimals.sub(18)))
                : unsignedPremium.div(10 ** (uint256(18).sub(decimals)));

            premium = params.premium < 0 ? -int256(unsignedPremium) : int256(unsignedPremium);

            if (premium > type(int96).max) revert VL_Overflow();
        }

        if (premium < 0)
            biddingToken.safeApproveNonCompliant(
                params.auctionAddr,
                unsignedPremium.mulDivUp(params.structures, Vault.UNIT)
            );

        auctionId = IBatchAuction(params.auctionAddr).createAuction(
            IMarginEngine(params.engineAddr).optionToken(),
            params.optionTokens,
            params.biddingToken,
            marginCollateralsToAuctionCollaterals(params.collaterals, params.counterparty, params.maxStructures),
            int96(premium),
            1,
            uint64(params.structures),
            block.timestamp.add(params.duration),
            params.whitelist
        );

        emit CreatedAuction(params.optionTokens, params.biddingToken, auctionId, msg.sender);
    }

    function marginCollateralsToAuctionCollaterals(
        Vault.Collateral[] calldata vaultCollaterals,
        uint256[] calldata balances,
        uint256 maxStructures
    ) internal pure returns (IBatchAuction.Collateral[] memory collaterals) {
        collaterals = new IBatchAuction.Collateral[](balances.length);

        for (uint256 i; i < balances.length; ) {
            uint256 amount = balances[i].mulDivUp(Vault.UNIT, maxStructures);

            if (amount > type(uint80).max) revert VL_Overflow();

            collaterals[i] = IBatchAuction.Collateral(vaultCollaterals[i].addr, uint80(amount));

            unchecked {
                ++i;
            }
        }
    }

    // function grappaBalanceForCollateral(address engineAddr, address collateralAddr)
    //     external
    //     view
    //     returns (uint256 amount)
    // {
    //     IMarginEngine engine = IMarginEngine(engineAddr);
    //     IGrappa grappa = IGrappa(engine.grappa());

    //     uint8 collateralId = grappa.assetIds(collateralAddr);

    //     (, , Grappa.Balance[] memory collaterals) = engine.marginAccounts(address(this));

    //     uint256 i;
    //     do {
    //         if (collaterals[i].collateralId == collateralId) {
    //             amount = collaterals[i].amount;
    //             break;
    //         }
    //         unchecked {
    //             ++i;
    //         }
    //     } while (i < collaterals.length);
    // }

    function settleAuction(
        address auctionAddr,
        uint256 optionAuctionId
    ) external returns (int256 clearingPrice, uint256 totalSold) {
        (clearingPrice, totalSold) = IBatchAuction(auctionAddr).settleAuction(optionAuctionId);
    }

    /**
     * @notice Verify the constructor params satisfy requirements
     * @param initParams is the struct with vault general data
     * @param vaultParams is the struct with vault general data
     */
    function verifyInitializerParams(
        Vault.InitParams calldata initParams,
        Vault.VaultParams calldata vaultParams
    ) external pure {
        if (initParams._owner == address(0)) revert VL_BadOwnerAddress();
        if (initParams._keeper == address(0)) revert VL_BadKeeperAddress();
        if (initParams._feeRecipient == address(0)) revert VL_BadFeeAddress();
        if (initParams._oracle == address(0)) revert VL_BadOracleAddress();
        if (initParams._vaultPauser == address(0)) revert VL_BadPauserAddress();
        if (
            initParams._performanceFee > 100 * Vault.FEE_MULTIPLIER ||
            initParams._managementFee > 100 * Vault.FEE_MULTIPLIER
        ) revert VL_BadFee();
        if (bytes(initParams._tokenName).length == 0 || bytes(initParams._tokenSymbol).length == 0)
            revert VL_BadToken();

        if (initParams._instruments.length == 0) revert VL_BadInstruments();

        for (uint256 i; i < initParams._instruments.length; ) {
            if (initParams._instruments[i].weight == 0) revert VL_BadWeight();
            if (initParams._instruments[i].oracle == address(0)) revert VL_BadOracleAddress();
            if (initParams._instruments[i].underlying == address(0)) revert VL_BadUnderlyingAddress();
            if (initParams._instruments[i].strike == address(0)) revert VL_BadStrikeAddress();
            if (initParams._instruments[i].collateral == address(0)) revert VL_BadCollateralAddress();

            unchecked {
                ++i;
            }
        }

        if (initParams._collaterals.length == 0) revert VL_BadCollateral();
        for (uint256 i; i < initParams._collaterals.length; ) {
            if (initParams._collaterals[i].id == 0) revert VL_BadCollateral();
            if (initParams._collaterals[i].addr == address(0)) revert VL_BadCollateralAddress();
            if (initParams._collaterals[i].decimals == 0) revert VL_BadPrecision();

            unchecked {
                ++i;
            }
        }

        if (vaultParams.minimumSupply == 0) revert VL_BadSupply();
        if (vaultParams.cap == 0) revert VL_BadCap();
        if (vaultParams.cap <= vaultParams.minimumSupply) revert VL_BadCap();

        if (
            initParams._roundConfig.duration == 0 ||
            initParams._roundConfig.dayOfWeek > 8 ||
            initParams._roundConfig.hourOfDay >= 24
        ) revert VL_BadDuration();
    }

    /**
     * @notice Gets the next option expiry from the given timestamp
     * @param roundConfig the configuration used to calculate the option expiry
     */
    function getNextExpiry(Vault.RoundConfig storage roundConfig) internal view returns (uint256 nextTime) {
        uint256 offset = block.timestamp + roundConfig.duration;

        // The offset will always be greater than the options expiry, so we subtract a week in order to get the day the option should expire, or subtract a day to get the hour the option should start if the dayOfWeek is wild (8)
        if (roundConfig.dayOfWeek != 8) offset -= 1 weeks;
        else offset -= 1 days;

        nextTime = getNextDayTimeOfWeek(offset, roundConfig.dayOfWeek, roundConfig.hourOfDay);

        //if timestamp is in the past relative to the offset, it means we've tried to calculate an expiry of an option which has too short of length. I.e trying to run a 1 day option on a Tuesday which should expire Friday
        if (nextTime < offset) revert VL_BadExpiryDate();
    }

    /**
     * @notice Calculates the next day/hour of the week
     * @param timestamp is the expiry timestamp of the current option
     * @param dayOfWeek is the day of the week we're looking for (sun:0/7 - sat:6), 8 will be treated as disabled and the next available hourOfDay will be returned
     * @param hourOfDay is the next hour of the day we want to expire on (midnight:0)
     *
     * Examples when day = 5, hour = 8:
     * getNextDayTimeOfWeek(week 1 thursday) -> week 1 friday:0800
     * getNextDayTimeOfWeek(week 1 friday) -> week 2 friday:0800
     * getNextDayTimeOfWeek(week 1 saturday) -> week 2 friday:0800
     *
     * Examples when day = 7, hour = 8:
     * getNextDayTimeOfWeek(week 1 thursday) -> week 1 friday:0800
     * getNextDayTimeOfWeek(week 1 friday:0500) -> week 1 friday:0800
     * getNextDayTimeOfWeek(week 1 friday:0900) -> week 1 saturday:0800
     * getNextDayTimeOfWeek(week 1 saturday) -> week 1 sunday:0800
     */
    function getNextDayTimeOfWeek(
        uint256 timestamp,
        uint256 dayOfWeek,
        uint256 hourOfDay
    ) internal pure returns (uint256 nextStartTime) {
        // we want sunday to have a value of 7
        if (dayOfWeek == 0) dayOfWeek = 7;

        // dayOfWeek = 0 (sunday) - 6 (saturday) calculated from epoch time
        uint256 timestampDayOfWeek = ((timestamp / 1 days) + 4) % 7;
        //Calculate the nextDayOfWeek by figuring out how much time is between now and then in seconds
        uint256 nextDayOfWeek = timestamp +
            ((7 + (dayOfWeek == 8 ? timestampDayOfWeek : dayOfWeek) - timestampDayOfWeek) % 7) *
            1 days;
        //Calculate the nextStartTime by removing the seconds past midnight, then adding the amount seconds after midnight we wish to start
        nextStartTime = nextDayOfWeek - (nextDayOfWeek % 24 hours) + (hourOfDay * 1 hours);

        // If the date has passed, we simply increment it by a week to get the next dayOfWeek, or by a day if we only want the next hourOfDay
        if (timestamp >= nextStartTime)
            if (dayOfWeek == 8) nextStartTime += 1 days;
            else nextStartTime += 7 days;
    }

    // function filterInstruments(bool forVault, uint256[] tokenIds, Vault.Instrument[] instruments)
    //     private
    //     pure
    //     returns (uint256[] memory, Vault.Instrument[] memory)
    // {
    //     Vault.Instrument[] filtered
    // }

    function isOptionExpired(uint256 tokenId) internal view returns (bool expired) {
        expired = tokenId.isExpired();
    }

    function toUint256(int256 variable) internal pure returns (uint256) {
        if (variable < 0) {
            return uint256(-variable);
        } else {
            return uint256(variable);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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

    function unsafeMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            // Mod x by y. Note this will return
            // 0 instead of reverting if y is zero.
            z := mod(x, y)
        }
    }

    function unsafeDiv(uint256 x, uint256 y) internal pure returns (uint256 r) {
        assembly {
            // Divide x by y. Note this will return
            // 0 instead of reverting if y is zero.
            r := div(x, y)
        }
    }

    function unsafeDivUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            // Add 1 to x * y if x % y > 0. Note this will
            // return 0 instead of reverting if y is zero.
            z := add(gt(mod(x, y), 0), div(x, y))
        }
    }
}

// SPDX-License-Identifier: MIT

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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
// solhint-disable max-line-length

pragma solidity ^0.8.0;

import "../config/enums.sol";
import "../config/errors.sol";

/**
 * Token ID =
 *
 *  * ------------------- | ------------------- | ---------------- | -------------------- | --------------------- *
 *  | tokenType (24 bits) | productId (40 bits) | expiry (64 bits) | longStrike (64 bits) | shortStrike (64 bits) |
 *  * ------------------- | ------------------- | ---------------- | -------------------- | --------------------- *
 */

/**
 * Compressed Token ID =
 *
 *  * ------------------- | ------------------- | ---------------- | -------------------- *
 *  | tokenType (24 bits) | productId (40 bits) | expiry (64 bits) | longStrike (64 bits) |
 *  * ------------------- | ------------------- | ---------------- | -------------------- *
 */
library TokenIdUtil {
    function getTokenId(TokenType tokenType, uint40 productId, uint256 expiry, uint256 longStrike, uint256 shortStrike)
        internal
        pure
        returns (uint256 tokenId)
    {
        tokenId = formatTokenId(tokenType, productId, uint64(expiry), uint64(longStrike), uint64(shortStrike));
    }

    /**
     * @notice calculate ERC1155 token id for given option parameters. See table above for tokenId
     * @param tokenType TokenType enum
     * @param productId if of the product
     * @param expiry timestamp of option expiry
     * @param longStrike strike price of the long option, with 6 decimals
     * @param shortStrike strike price of the short (upper bond for call and lower bond for put) if this is a spread. 6 decimals
     * @return tokenId token id
     */
    function formatTokenId(TokenType tokenType, uint40 productId, uint64 expiry, uint64 longStrike, uint64 shortStrike)
        internal
        pure
        returns (uint256 tokenId)
    {
        unchecked {
            tokenId = (uint256(tokenType) << 232) + (uint256(productId) << 192) + (uint256(expiry) << 128)
                + (uint256(longStrike) << 64) + uint256(shortStrike);
        }
    }

    /**
     * @notice calculate non-complaint ERC1155 token id for given option parameters. See table above for shorttokenId
     * @param tokenType TokenType enum
     * @param productId if of the product
     * @param expiry timestamp of option expiry
     * @param longStrike strike price of the long option, with 6 decimals
     * @return tokenId token id
     */
    function formatShortTokenId(TokenType tokenType, uint40 productId, uint64 expiry, uint64 longStrike)
        internal
        pure
        returns (uint192 tokenId)
    {
        unchecked {
            tokenId = (uint192(tokenType) << 168) + (uint192(productId) << 128) + (uint192(expiry) << 64) + uint192(longStrike);
        }
    }

    /**
     * @notice derive option, product, expiry and strike price from ERC1155 token id
     * @dev    See table above for tokenId composition
     * @param tokenId token id
     * @return tokenType TokenType enum
     * @return productId 32 bits product id
     * @return expiry timestamp of option expiry
     * @return longStrike strike price of the long option, with 6 decimals
     * @return shortStrike strike price of the short (upper bond for call and lower bond for put) if this is a spread. 6 decimals
     */
    function parseTokenId(uint256 tokenId)
        internal
        pure
        returns (TokenType tokenType, uint40 productId, uint64 expiry, uint64 longStrike, uint64 shortStrike)
    {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            tokenType := shr(232, tokenId)
            productId := shr(192, tokenId)
            expiry := shr(128, tokenId)
            longStrike := shr(64, tokenId)
            shortStrike := tokenId
        }
    }

    /**
     * @notice parse collateral id from tokenId
     * @dev more efficient than parsing tokenId and than parse productId
     * @param tokenId token id
     * @return collatearlId
     */
    function parseCollateralId(uint256 tokenId) internal pure returns (uint8 collatearlId) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // collateralId is the last bits of productId
            collatearlId := shr(192, tokenId)
        }
    }

    /**
     * @notice parse engine id from tokenId
     * @dev more efficient than parsing tokenId and than parse productId
     * @param tokenId token id
     * @return engineId
     */
    function parseEnginelId(uint256 tokenId) internal pure returns (uint8 engineId) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // collateralId is the last bits of productId
            engineId := shr(216, tokenId) // 192 to get product id, another 24 to get engineId
        }
    }

    /**
     * @notice derive option, product, expiry and strike price from short token id (no shortStrike)
     * @dev    See table above for tokenId composition
     * @param tokenId token id
     * @return tokenType TokenType enum
     * @return productId 32 bits product id
     * @return expiry timestamp of option expiry
     * @return longStrike strike price of the long option, with 6 decimals
     */
    function parseShortTokenId(uint192 tokenId)
        internal
        pure
        returns (TokenType tokenType, uint40 productId, uint64 expiry, uint64 longStrike)
    {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            tokenType := shr(168, tokenId)
            productId := shr(128, tokenId)
            expiry := shr(64, tokenId)
            longStrike := tokenId
        }
    }

    /**
     * @notice derive option type from ERC1155 token id
     * @param tokenId token id
     * @return tokenType TokenType enum
     */
    function parseTokenType(uint256 tokenId) internal pure returns (TokenType tokenType) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            tokenType := shr(232, tokenId)
        }
    }

    /**
     * @notice derive if option is expired from ERC1155 token id
     * @param tokenId token id
     * @return expired bool
     */
    function isExpired(uint256 tokenId) internal view returns (bool expired) {
        uint64 expiry;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            expiry := shr(128, tokenId)
        }

        expired = block.timestamp >= expiry;
    }

    /**
     * @notice convert an spread tokenId back to put or call.
     *                  * ------------------- | ------------------- | ---------------- | -------------------- | --------------------- *
     * @dev   oldId =   | spread type (24 b)  | productId (40 bits) | expiry (64 bits) | longStrike (64 bits) | shortStrike (64 bits) |
     *                  * ------------------- | ------------------- | ---------------- | -------------------- | --------------------- *
     *                  * ------------------- | ------------------- | ---------------- | -------------------- | --------------------- *
     * @dev   newId =   | call or put type    | productId (40 bits) | expiry (64 bits) | longStrike (64 bits) | 0           (64 bits) |
     *                  * ------------------- | ------------------- | ---------------- | -------------------- | --------------------- *
     * @dev   this function will: override tokenType, remove shortStrike.
     * @param _tokenId token id to change
     */
    function convertToVanillaId(uint256 _tokenId) internal pure returns (uint256 newId) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            newId := shr(64, _tokenId) // step 1: >> 64 to wipe out shortStrike
            newId := shl(64, newId) // step 2: << 64 go back

            newId := sub(newId, shl(232, 1)) // step 3: new tokenType = spread type - 1
        }
    }

    /**
     * @notice convert an spread tokenId back to put or call.
     *                  * ------------------- | ------------------- | ---------------- | -------------------- | --------------------- *
     * @dev   oldId =   | call or put type    | productId (40 bits) | expiry (64 bits) | longStrike (64 bits) | 0           (64 bits) |
     *                  * ------------------- | ------------------- | ---------------- | -------------------- | --------------------- *
     *                  * ------------------- | ------------------- | ---------------- | -------------------- | --------------------- *
     * @dev   newId =   | spread type         | productId (40 bits) | expiry (64 bits) | longStrike (64 bits) | shortStrike (64 bits) |
     *                  * ------------------- | ------------------- | ---------------- | -------------------- | --------------------- *
     *
     * this function convert put or call type to spread type, add shortStrike.
     * @param _tokenId token id to change
     * @param _shortStrike strike to add
     */
    function convertToSpreadId(uint256 _tokenId, uint256 _shortStrike) internal pure returns (uint256 newId) {
        // solhint-disable-next-line no-inline-assembly
        unchecked {
            newId = _tokenId + _shortStrike;
            return newId + (1 << 232); // new type (spread type) = old type + 1
        }
    }

    /**
     * @notice Compresses tokenId by removing shortStrike.
     *                  * ------------------- | ------------------- | ---------------- | -------------------- | --------------------- *
     * @dev   oldId =   | call or put type    | productId (40 bits) | expiry (64 bits) | longStrike (64 bits) | 0           (64 bits) |
     *                  * ------------------- | ------------------- | ---------------- | -------------------- | --------------------- *
     *                  * ------------------- | ------------------- | ---------------- | -------------------- *
     * @dev   newId =   | call or put type    | productId (40 bits) | expiry (64 bits) | longStrike (64 bits) |
     *                  * ------------------- | ------------------- | ---------------- | -------------------- *
     *
     * @param _tokenId token id to change
     */
    function compress(uint256 _tokenId) internal pure returns (uint192 newId) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            newId := shr(64, _tokenId) // >> 64 to wipe out shortStrike
        }
    }

    /**
     * @notice convert a shortened tokenId back ERC1155 compliant.
     *                  * ------------------- | ------------------- | ---------------- | -------------------- *
     * @dev   oldId =   | call or put type    | productId (40 bits) | expiry (64 bits) | longStrike (64 bits) |
     *                  * ------------------- | ------------------- | ---------------- | -------------------- *
     *                  * ------------------- | ------------------- | ---------------- | -------------------- | --------------------- *
     * @dev   newId =   | call or put type    | productId (40 bits) | expiry (64 bits) | longStrike (64 bits) | 0           (64 bits) |
     *                  * ------------------- | ------------------- | ---------------- | -------------------- | --------------------- *
     *
     * @param _tokenId token id to change
     */
    function expand(uint192 _tokenId) internal pure returns (uint256 newId) {
        newId = uint256(_tokenId);
        // solhint-disable-next-line no-inline-assembly
        assembly {
            newId := shl(64, newId)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// solhint-disable max-line-length

/**
 * @title ProductIdUtil
 * @dev used to parse and compose productId
 * Product Id =
 * * ----------------- | ----------------- | ---------------------- | ------------------ | ---------------------- *
 * | oracleId (8 bits) | engineId (8 bits) | underlying ID (8 bits) | strike ID (8 bits) | collateral ID (8 bits) |
 * * ----------------- | ----------------- | ---------------------- | ------------------ | ---------------------- *
 *
 */
library ProductIdUtil {
    /**
     * @dev parse product id into composing asset ids
     *
     * productId (40 bits) =
     *
     * @param _productId product id
     */
    function parseProductId(uint40 _productId)
        internal
        pure
        returns (uint8 oracleId, uint8 engineId, uint8 underlyingId, uint8 strikeId, uint8 collateralId)
    {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            oracleId := shr(32, _productId)
            engineId := shr(24, _productId)
            underlyingId := shr(16, _productId)
            strikeId := shr(8, _productId)
        }
        collateralId = uint8(_productId);
    }

    /**
     * @dev parse collateral id from product Id.
     *      since collateral id is uint8 of the last 8 bits of productId, we can just cast to uint8
     */
    function getCollateralId(uint40 _productId) internal pure returns (uint8) {
        return uint8(_productId);
    }

    /**
     * @notice    get product id from underlying, strike and collateral address
     * @dev       function will still return even if some of the assets are not registered
     * @param underlyingId  underlying id
     * @param strikeId      strike id
     * @param collateralId  collateral id
     */
    function getProductId(uint8 oracleId, uint8 engineId, uint8 underlyingId, uint8 strikeId, uint8 collateralId)
        internal
        pure
        returns (uint40 id)
    {
        unchecked {
            id = (uint40(oracleId) << 32) + (uint40(engineId) << 24) + (uint40(underlyingId) << 16) + (uint40(strikeId) << 8)
                + (uint40(collateralId));
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../config/enums.sol";
import "../config/types.sol";

/**
 * @title libraries to encode action arguments
 * @dev   only used in tests
 */
library ActionUtil {
    /**
     * @param collateralId id of collateral
     * @param amount amount of collateral to deposit
     * @param from address to pull asset from
     */
    function createAddCollateralAction(uint8 collateralId, uint256 amount, address from)
        internal
        pure
        returns (ActionArgs memory action)
    {
        action = ActionArgs({action: ActionType.AddCollateral, data: abi.encode(from, uint80(amount), collateralId)});
    }

    /**
     * @param collateralId id of collateral
     * @param amount amount of collateral to remove
     * @param recipient address to receive removed collateral
     */
    function createRemoveCollateralAction(uint8 collateralId, uint256 amount, address recipient)
        internal
        pure
        returns (ActionArgs memory action)
    {
        action = ActionArgs({action: ActionType.RemoveCollateral, data: abi.encode(uint80(amount), recipient, collateralId)});
    }

    /**
     * @param collateralId id of collateral
     * @param amount amount of collateral to remove
     * @param recipient address to receive removed collateral
     */
    function createTransferCollateralAction(uint8 collateralId, uint256 amount, address recipient)
        internal
        pure
        returns (ActionArgs memory action)
    {
        action = ActionArgs({action: ActionType.TransferCollateral, data: abi.encode(uint80(amount), recipient, collateralId)});
    }

    /**
     * @param tokenId option token id to mint
     * @param amount amount of token to mint (6 decimals)
     * @param recipient address to receive minted option
     */
    function createMintAction(uint256 tokenId, uint256 amount, address recipient)
        internal
        pure
        returns (ActionArgs memory action)
    {
        action = ActionArgs({action: ActionType.MintShort, data: abi.encode(tokenId, recipient, uint64(amount))});
    }

    /**
     * @param tokenId option token id to mint
     * @param amount amount of token to mint (6 decimals)
     * @param subAccount sub account to receive minted option
     */
    function createMintIntoAccountAction(uint256 tokenId, uint256 amount, address subAccount)
        internal
        pure
        returns (ActionArgs memory action)
    {
        action = ActionArgs({action: ActionType.MintShortIntoAccount, data: abi.encode(tokenId, subAccount, uint64(amount))});
    }

    /**
     * @param tokenId option token id to mint
     * @param amount amount of token to mint (6 decimals)
     * @param recipient account to receive minted option
     */
    function createTranferLongAction(uint256 tokenId, uint256 amount, address recipient)
        internal
        pure
        returns (ActionArgs memory action)
    {
        action = ActionArgs({action: ActionType.TransferLong, data: abi.encode(tokenId, recipient, uint64(amount))});
    }

    /**
     * @param tokenId option token id to mint
     * @param amount amount of token to mint (6 decimals)
     * @param recipient account to receive minted option
     */
    function createTranferShortAction(uint256 tokenId, uint256 amount, address recipient)
        internal
        pure
        returns (ActionArgs memory action)
    {
        action = ActionArgs({action: ActionType.TransferShort, data: abi.encode(tokenId, recipient, uint64(amount))});
    }

    /**
     * @param tokenId option token id to burn
     * @param amount amount of token to burn (6 decimals)
     * @param from address to burn option token from
     */
    function createBurnAction(uint256 tokenId, uint256 amount, address from) internal pure returns (ActionArgs memory action) {
        action = ActionArgs({action: ActionType.BurnShort, data: abi.encode(tokenId, from, uint64(amount))});
    }

    /**
     * @param tokenId option token id of the incoming option token.
     * @param shortId the currently shorted "option token id" to merge the option token into
     * @param amount amount to merge
     * @param from which address to burn the incoming option from.
     */
    function createMergeAction(uint256 tokenId, uint256 shortId, uint256 amount, address from)
        internal
        pure
        returns (ActionArgs memory action)
    {
        action = ActionArgs({action: ActionType.MergeOptionToken, data: abi.encode(tokenId, shortId, from, amount)});
    }

    /**
     * @param spreadId current shorted "spread option id"
     * @param amount amount to split
     * @param recipient address to receive the "splited" long option token.
     */
    function createSplitAction(uint256 spreadId, uint256 amount, address recipient)
        internal
        pure
        returns (ActionArgs memory action)
    {
        action = ActionArgs({action: ActionType.SplitOptionToken, data: abi.encode(spreadId, uint64(amount), recipient)});
    }

    /**
     * @param tokenId option token to be added to the account
     * @param amount amount to add
     * @param from address to pull the token from
     */
    function createAddLongAction(uint256 tokenId, uint256 amount, address from)
        internal
        pure
        returns (ActionArgs memory action)
    {
        action = ActionArgs({action: ActionType.AddLong, data: abi.encode(tokenId, uint64(amount), from)});
    }

    /**
     * @param tokenId option token to be removed from an account
     * @param amount amount to remove
     * @param recipient address to receive the removed option
     */
    function createRemoveLongAction(uint256 tokenId, uint256 amount, address recipient)
        internal
        pure
        returns (ActionArgs memory action)
    {
        action = ActionArgs({action: ActionType.RemoveLong, data: abi.encode(tokenId, uint64(amount), recipient)});
    }

    /**
     * @dev create action to settle an account
     */
    function createSettleAction() internal pure returns (ActionArgs memory action) {
        action = ActionArgs({action: ActionType.SettleAccount, data: abi.encode(0)});
    }

    function concat(ActionArgs[] memory x, ActionArgs[] memory v) internal pure returns (ActionArgs[] memory y) {
        y = new ActionArgs[](x.length + v.length);
        uint256 z;
        uint256 i;
        for (i; i < x.length;) {
            y[z] = x[i];
            unchecked {
                ++z;
                ++i;
            }
        }
        for (i = 0; i < v.length;) {
            y[z] = v[i];
            unchecked {
                ++z;
                ++i;
            }
        }
    }

    function append(ActionArgs[] memory x, ActionArgs memory v) internal pure returns (ActionArgs[] memory y) {
        y = new ActionArgs[](x.length + 1);
        uint256 i;
        for (i; i < x.length;) {
            y[i] = x[i];
            unchecked {
                ++i;
            }
        }
        y[i] = v;
    }

    function append(BatchExecute[] memory x, BatchExecute memory v) internal pure returns (BatchExecute[] memory y) {
        y = new BatchExecute[](x.length + 1);
        uint256 i;
        for (i; i < x.length;) {
            y[i] = x[i];
            unchecked {
                ++i;
            }
        }
        y[i] = v;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../../libraries/TokenIdUtil.sol";
import "../../../libraries/ArrayUtil.sol";

// cross margin types
import "./types.sol";

library AccountUtil {
    using TokenIdUtil for uint192;
    using TokenIdUtil for uint256;

    function append(CrossMarginDetail[] memory x, CrossMarginDetail memory v)
        internal
        pure
        returns (CrossMarginDetail[] memory y)
    {
        y = new CrossMarginDetail[](x.length + 1);
        uint256 i;
        for (i; i < x.length;) {
            y[i] = x[i];
            unchecked {
                ++i;
            }
        }
        y[i] = v;
    }

    function append(Position[] memory x, Position memory v) internal pure returns (Position[] memory y) {
        y = new Position[](x.length + 1);
        uint256 i;
        for (i; i < x.length;) {
            y[i] = x[i];
            unchecked {
                ++i;
            }
        }
        y[i] = v;
    }

    function concat(Position[] memory a, Position[] memory b) internal pure returns (Position[] memory y) {
        y = new Position[](a.length + b.length);
        uint256 v;
        uint256 i;
        for (i; i < a.length;) {
            y[v] = a[i];
            unchecked {
                ++i;
                ++v;
            }
        }
        for (i = 0; i < b.length;) {
            y[v] = b[i];
            unchecked {
                ++i;
                ++v;
            }
        }
    }

    /// @dev currently unused
    function find(Position[] memory x, uint256 v) internal pure returns (bool f, Position memory p, uint256 i) {
        for (i; i < x.length;) {
            if (x[i].tokenId == v) {
                p = x[i];
                f = true;
                break;
            }
            unchecked {
                ++i;
            }
        }
    }

    function find(PositionOptim[] memory x, uint192 v) internal pure returns (bool f, PositionOptim memory p, uint256 i) {
        for (i; i < x.length;) {
            if (x[i].tokenId == v) {
                p = x[i];
                f = true;
                break;
            }
            unchecked {
                ++i;
            }
        }
    }

    function indexOf(Position[] memory x, uint256 v) internal pure returns (bool f, uint256 i) {
        for (i; i < x.length;) {
            if (x[i].tokenId == v) {
                f = true;
                break;
            }
            unchecked {
                ++i;
            }
        }
    }

    function indexOf(PositionOptim[] memory x, uint192 v) internal pure returns (bool f, uint256 i) {
        for (i; i < x.length;) {
            if (x[i].tokenId == v) {
                f = true;
                break;
            }
            unchecked {
                ++i;
            }
        }
    }

    function sum(PositionOptim[] memory x) internal pure returns (uint64 s) {
        for (uint256 i; i < x.length;) {
            s += x[i].amount;
            unchecked {
                ++i;
            }
        }
    }

    function getPositions(PositionOptim[] memory x) internal pure returns (Position[] memory y) {
        y = new Position[](x.length);
        for (uint256 i; i < x.length;) {
            y[i] = Position(x[i].tokenId.expand(), x[i].amount);
            unchecked {
                ++i;
            }
        }
    }

    function getPositionOptims(Position[] memory x) internal pure returns (PositionOptim[] memory y) {
        y = new PositionOptim[](x.length);
        for (uint256 i; i < x.length;) {
            y[i] = getPositionOptim(x[i]);
            unchecked {
                ++i;
            }
        }
    }

    function pushPosition(PositionOptim[] storage x, Position memory y) internal {
        x.push(getPositionOptim(y));
    }

    function removePositionAt(PositionOptim[] storage x, uint256 y) internal {
        if (y >= x.length) return;
        x[y] = x[x.length - 1];
        x.pop();
    }

    function getPositionOptim(Position memory x) internal pure returns (PositionOptim memory) {
        return PositionOptim(x.tokenId.compress(), x.amount);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.4;

import { TokenType } from "../../lib/grappa/src/config/enums.sol";

library Vault {
    /************************************************
     *  IMMUTABLES & CONSTANTS
     ***********************************************/

    // Fees are 6-decimal places. For example: 20 * 10**6 = 20%
    uint256 internal constant FEE_MULTIPLIER = 10 ** 6;

    // Otokens have 6 decimal places.
    uint256 internal constant DECIMALS = 6;

    // Otokens have 6 decimal places.
    uint256 internal constant UNIT = 10 ** 6;

    // Placeholder uint value to prevent cold writes
    uint256 internal constant PLACEHOLDER_UINT = 1;

    /**
     * @notice Initialization parameters for the vault.
     * @param _owner is the owner of the vault with critical permissions
     * @param _feeRecipient is the address to recieve vault performance and management fees
     * @param _managementFee is the management fee pct.
     * @param _performanceFee is the perfomance fee pct.
     * @param _tokenName is the name of the token
     * @param _tokenSymbol is the symbol of the token
     * @param _auctionDuration is the duration of the gnosis auction
     * @param _instruments linear combination of options
     */
    struct InitParams {
        address _owner;
        address _keeper;
        address _feeRecipient;
        address _oracle;
        uint256 _managementFee;
        uint256 _performanceFee;
        string _tokenName;
        string _tokenSymbol;
        address _vaultPauser;
        Instrument[] _instruments;
        Collateral[] _collaterals;
        uint256 _auctionDuration;
        uint256 _leverageRatio;
        RoundConfig _roundConfig;
    }

    struct Collateral {
        // Grappa asset Id
        uint8 id;
        // ERC20 token address for the required collateral
        address addr;
        // the amount of decimals or token
        uint8 decimals;
    }

    struct Instrument {
        TokenType tokenType;
        // Indicated how much the vault is short or long this instrument in a structure
        int64 weight;
        // oracle for product
        address oracle;
        // Underlying asset of the options
        address underlying;
        // asset that the strike price is denominated in
        address strike;
        // Asset backing the option
        address collateral;
    }

    struct VaultParams {
        // Minimum supply of the vault shares issued, for ETH it's 10**10
        uint56 minimumSupply;
        // Vault cap
        uint104 cap;
    }

    struct OptionState {
        // Option that the vault is shorting / longing in the next cycle
        uint256[] nextOptions;
        // Option that the vault is currently shorting / longing
        uint256[] currentOptions;
        // Current premium per structure
        int256 premium;
        // Max number of structures possible to sell based on
        // = lockedBalance * leverageRatio
        uint256 maxStructures;
        // Total structures minted this round
        uint256 mintedStructures;
        // Amount of collateral required by the vault per structure
        uint256[] vault;
        // Amount of collateral required by the counterparty per structure
        uint256[] counterparty;
    }

    struct VaultState {
        // 32 byte slot 1
        // Round represents the number of periods elapsed. There's a hard limit of 4,294,967,295 rounds
        uint32 round;
        // Amount that is currently locked for selling options
        uint104 lockedAmount;
        // Amount that was locked for selling options in the previous round
        // used for calculating performance fee deduction
        uint104 lastLockedAmount;
        // 32 byte slot 2
        // Stores the total tally of how much of `asset` there is
        // to be used to mint vault tokens
        uint128 totalPending;
        // store the number of shares queued for withdraw this round
        // zero'ed out at the start of each round, pauser withdraws all queued shares.
        uint128 queuedWithdrawShares;
    }

    struct DepositReceipt {
        // Round represents the number of periods elapsed. There's a hard limit of 4,294,967,295 rounds
        uint32 round;
        // Deposit amount, max 20,282,409,603,651 or 20 trillion ETH deposit
        uint104 amount;
        // Unredeemed shares balance
        uint128 unredeemedShares;
    }

    struct Withdrawal {
        // Round represents the number of periods elapsed. There's a hard limit of 4,294,967,295 rounds
        uint32 round;
        // Number of shares withdrawn
        uint128 shares;
    }

    struct RoundConfig {
        // the duration of the auction
        uint32 duration;
        // day of the week the auction should begin. 0-8, 0 is sunday, 7 is sunday, 8 is wild
        uint8 dayOfWeek;
        // hour of the day the auction should begin. 0 is midnight
        uint8 hourOfDay;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.4;

import { FixedPointMathLib } from "solmate/src/utils/FixedPointMathLib.sol";
import { Vault } from "./Vault.sol";
import "../utils/Error.sol";

library ShareMath {
    using FixedPointMathLib for uint256;

    function navToShares(uint256 nav, uint256 navPerShare) internal pure returns (uint256) {
        // If this throws, it means that vault's roundPricePerShare[currentRound] has not been set yet
        // which should never happen.
        // Has to be larger than 1 because `1` is used in `initRoundPricePerShares` to prevent cold writes.
        if (navPerShare <= Vault.PLACEHOLDER_UINT) revert SM_NPSLow();

        return nav.mulDivDown(Vault.UNIT, navPerShare);
    }

    function sharesToNAV(uint256 shares, uint256 navPerShare) internal pure returns (uint256) {
        // If this throws, it means that vault's roundPricePerShare[currentRound] has not been set yet
        // which should never happen.
        // Has to be larger than 1 because `1` is used in `initRoundPricePerShares` to prevent cold writes.
        if (navPerShare <= Vault.PLACEHOLDER_UINT) revert SM_NPSLow();

        return shares.mulDivDown(navPerShare, Vault.UNIT);
    }

    /**
     * @notice Returns the shares unredeemed by the user given their DepositReceipt
     * @param depositReceipt is the user's deposit receipt
     * @param currentRound is the `round` stored on the vault
     * @param navPerShare is the price in asset per share
     * @return unredeemedShares is the user's virtual balance of shares that are owed
     */
    function getSharesFromReceipt(
        Vault.DepositReceipt memory depositReceipt,
        uint256 currentRound,
        uint256 navPerShare,
        uint256 depositNAV
    ) internal pure returns (uint256 unredeemedShares) {
        if (depositReceipt.round > 0 && depositReceipt.round < currentRound) {
            uint256 sharesFromRound = navToShares(depositNAV, navPerShare);

            return uint256(depositReceipt.unredeemedShares) + sharesFromRound;
        }
        return depositReceipt.unredeemedShares;
    }

    function pricePerShare(
        uint256 totalSupply,
        uint256 totalBalanceNAV,
        uint256 pendingNAV
    ) internal pure returns (uint256) {
        return totalSupply > 0 ? (totalBalanceNAV - pendingNAV).mulDivDown(Vault.UNIT, totalSupply) : Vault.UNIT;
    }

    /************************************************
     *  HELPERS
     ***********************************************/

    function assertUint104(uint256 num) internal pure {
        if (num > type(uint104).max) revert SM_Overflow();
    }

    function assertUint128(uint256 num) internal pure {
        if (num > type(uint128).max) revert SM_Overflow();
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.4;
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * This library supports ERC20s that have quirks in their behavior.
 * One such ERC20 is USDT, which requires allowance to be 0 before calling approve.
 * We plan to update this library with ERC20s that display such idiosyncratic behavior.
 */
library SupportsNonCompliantERC20 {
    address private constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    function safeApproveNonCompliant(IERC20 token, address spender, uint256 amount) internal {
        if (address(token) == USDT) {
            SafeERC20.safeApprove(token, spender, 0);
        }
        SafeERC20.safeApprove(token, spender, amount);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.4;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Detailed is IERC20 {
    function decimals() external view returns (uint8);

    function symbol() external view returns (string calldata);

    function name() external view returns (string calldata);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.4;

import "../libraries/BatchAuctionQ.sol";

interface IBatchAuction {
    struct Collateral {
        //ERC20 token for the required collateral
        address addr;
        // The amount of tokens required for the collateral
        uint80 amount;
    }

    struct Auction {
        // Seller wallet address
        address seller;
        // ERC1155 address
        address optionTokenAddr;
        // ERC1155 Id of auctioned token
        uint256[] optionTokens;
        // ERC20 Token to bid for optionToken
        address biddingToken;
        // List of collateral requirements for each ERC20 token
        Collateral[] collaterals;
        // Price per optionToken denominated in biddingToken
        int96 minPrice;
        // Minimum optionToken amount acceptable for a single bid
        uint64 minBidSize;
        // Total available optionToken amount
        uint64 totalSize;
        // Remaining available optionToken amount
        // This figure is updated after each successfull bid
        uint256 availableSize;
        // Auction end time
        uint256 endTime;
        // clearing price
        int256 clearingPrice;
        // has the auction been settled
        bool settled;
        // whitelist address
        address whitelist;
    }

    function createAuction(
        address optionTokenAddr,
        uint256[] calldata optionTokens,
        address biddingToken,
        Collateral[] calldata collaterals,
        int96 minPrice,
        uint64 minBidSize,
        uint64 totalSize,
        uint256 endTime,
        address whitelist
    ) external returns (uint256 auctionId);

    function placeBid(
        uint256 auctionId,
        uint256 quantity,
        int256 price
    ) external;

    function removeBid(uint256 auctionId, uint256 bidId) external;

    function auctions(uint256) external view returns (IBatchAuction.Auction memory auction);

    function settleAuction(uint256 auctionId) external returns (int256 clearingPrice, uint256 totalSold);

    function claim(uint256 auctionId) external;

    function getBids(uint256 auctionId) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.4;

interface ISanctionsList {
    function isSanctioned(address _address) external view returns (bool);
}

interface IWhitelist {
    function isCustomer(address _address) external view returns (bool);

    function isLP(address _address) external view returns (bool);

    function isOTC(address _address) external view returns (bool);

    function isVault(address vault) external view returns (bool);

    function engineAccess(address _address) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.4;

//HashnoteVault
error HV_Unauthorized();
error HV_Initialized();
error HV_Uninitialized();
error HV_BadAddress();
error HV_BadAmount();
error HV_BadFee();
error HV_BadCap();
error HV_BadNumRounds();
error HV_BadDepositAmount();
error HV_BadNumShares();
error HV_BadRound();
error HV_ExistingWithdraw();
error HV_ExceedsCap();
error HV_ExceedsAvailable();
error HV_InsufficientFunds();
error HV_RoundNotClosed();
error HV_NotWhitelisted();
error HV_BadPPS();
error HV_BadExpiry();
error HV_BadSB();

//HashnoteOptionsVault
error HTV_Unauthorized();
error HTV_BadAddress();
error HTV_BadDuration();
error HTV_BadLevRatio();
error HTV_BadOption();
error HTV_BadStructures();
error HTV_RoundClosed();
error HTV_RoundNotClosed();
error HTV_ActiveRound();
error HTV_OptionNotExpired();
error HTV_BadNumStrikes();
error HTV_BadCollateralPosition();
error HTV_AuctionInProgress();
error HTV_BadCollaterals();

//HashnoteVaultPauser
error HVP_Unauthorized();
error HVP_BadAddress();
error HVP_PositionPaused();
error HVP_VaultNotFound();
error HVP_Overflow();
error HVP_RoundOpen();

//VaultLifecycle
error VL_BadProduct();
error VL_BadPrecision();
error VL_BadStrike();
error VL_Overflow();
error VL_BadOracleAddress();
error VL_BadGrappaAddress();
error VL_BadUnderlyingAddress();
error VL_BadStrikeAddress();
error VL_BadCollateralAddress();
error VL_BadPauserAddress();
error VL_BadFeeAddress();
error VL_BadKeeperAddress();
error VL_BadOwnerAddress();
error VL_BadFee();
error VL_BadToken();
error VL_BadWeight();
error VL_BadId();
error VL_BadCollateral();
error VL_BadCap();
error VL_BadSupply();
error VL_BadInstruments();
error VL_Unauthorized();
error VL_DifferentLengths();
error VL_ExceedsSurplus();
error VL_BadDuration();
error VL_BadExpiryDate();

//ShareMath
error SM_NPSLow();
error SM_Overflow();

//BatchAuction
error BA_Uninitialized();
error BA_Unauthorized();
error BA_BadAddress();
error BA_BadBiddingAddress();
error BA_BadOptionAddress();
error BA_BadOptions();
error BA_EmptyAuction();
error BA_BadTime();
error BA_BadCollateral();
error BA_BadAmount();
error BA_AuctionUnsettled();
error BA_AuctionSettled();
error BA_AuctionClosed();
error BA_AuctionNotClosed();
error BA_BadPrice();
error BA_BadSize();

//Whitelist
error WLM_BadAddress();
error WLM_BadRole();
error WLM_Unauthorized();

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
pragma solidity ^0.8.0;

// for easier import
import "../core/oracles/errors.sol";
import "../core/engines/full-margin/errors.sol";
import "../core/engines/advanced-margin/errors.sol";
import "../core/engines/cross-margin/errors.sol";

/* ------------------------ *
 *      Shared Errors       *
 * -----------------------  */

error NoAccess();

/* ------------------------ *
 *      Grappa Errors       *
 * -----------------------  */

/// @dev asset already registered
error GP_AssetAlreadyRegistered();

/// @dev margin engine already registered
error GP_EngineAlreadyRegistered();

/// @dev oracle already registered
error GP_OracleAlreadyRegistered();

/// @dev registring oracle doesn't comply with the max dispute period constraint.
error GP_BadOracle();

/// @dev amounts length speicified to batch settle doesn't match with tokenIds
error GP_WrongArgumentLength();

/// @dev cannot settle an unexpired option
error GP_NotExpired();

/// @dev settlement price is not finalized yet
error GP_PriceNotFinalized();

/// @dev cannot mint token after expiry
error GP_InvalidExpiry();

/// @dev put and call should not contain "short stirkes"
error GP_BadStrikes();

/// @dev burn or mint can only be called by corresponding engine.
error GP_Not_Authorized_Engine();

/* ---------------------------- *
 *   Common BaseEngine Errors   *
 * ---------------------------  */

/// @dev can only merge subaccount with put or call.
error BM_CannotMergeSpread();

/// @dev only spread position can be split
error BM_CanOnlySplitSpread();

/// @dev type of existing short token doesn't match the incoming token
error BM_MergeTypeMismatch();

/// @dev product type of existing short token doesn't match the incoming token
error BM_MergeProductMismatch();

/// @dev expiry of existing short token doesn't match the incoming token
error BM_MergeExpiryMismatch();

/// @dev cannot merge type with the same strike. (should use burn instead)
error BM_MergeWithSameStrike();

/// @dev account is not healthy / account is underwater
error BM_AccountUnderwater();

/// @dev msg.sender is not authorized to ask margin account to pull token from {from} address
error BM_InvalidFromAddress();

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

error OC_CannotReportForFuture();

error OC_PriceNotReported();

error OC_PriceReported();

///@dev cannot dispute the settlement price after dispute period is over
error OC_DisputePeriodOver();

///@dev cannot force-set an settlement price until grace period is passed and no one has set the price.
error OC_GracePeriodNotOver();

///@dev already disputed
error OC_PriceDisputed();

///@dev owner trying to set a dispute period that is invalid
error OC_InvalidDisputePeriod();

// Chainlink oracle

error CL_AggregatorNotSet();

error CL_StaleAnswer();

error CL_RoundIdTooSmall();

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/* ------------------------ *
 *    Full Margin Errors
 * -----------------------  */

/// @dev full margin doesn't support this action
error FM_UnsupportedAction();

/// @dev invalid collateral:
///         call can only be collateralized by underlying
///         put can only be collateralized by strike
error FM_CannotMintOptionWithThisCollateral();

/// @dev collateral id is wrong: the id doesn't match the existing collateral
error FM_WrongCollateralId();

/// @dev invalid tokenId specify to mint / burn actions
error FM_InvalidToken();

/// @dev trying to merge an long with a non-existant short position
error FM_ShortDoesnotExist();

/// @dev can only merge same amount of long and short
error FM_MergeAmountMisMatch();

/// @dev can only split same amount of existing spread into short + long
error FM_SplitAmountMisMatch();

/// @dev trying to collateralized the position with different collateral than specified in productId
error FM_CollateraliMisMatch();

/// @dev cannot override a non-empty subaccount id
error FM_AccountIsNotEmpty();

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/* ------------------------ *
 *  Advanced Margin Errors
 * -----------------------  */

/// @dev full margin doesn't support this action (add long and remove long)
error AM_UnsupportedAction();

/// @dev collateral id is wrong: the id doesn't match the existing collateral
error AM_WrongCollateralId();

/// @dev trying to merge an long with a non-existant short position
error AM_ShortDoesnotExist();

/// @dev can only merge same amount of long and short
error AM_MergeAmountMisMatch();

/// @dev can only split same amount of existing spread into short + long
error AM_SplitAmountMisMatch();

/// @dev invalid tokenId specify to mint / burn actions
error AM_InvalidToken();

/// @dev no config set for this asset.
error AM_NoConfig();

/// @dev cannot liquidate or takeover position: account is healthy
error AM_AccountIsHealthy();

/// @dev cannot override a non-empty subaccount id
error AM_AccountIsNotEmpty();

/// @dev amounts to repay in liquidation are not valid. Missing call, put or not proportional to the amount in subaccount.
error AM_WrongRepayAmounts();

// Vol Oracle

/// @dev cannot re-set aggregator
error VO_AggregatorAlreadySet();

/// @dev no aggregator set
error VO_AggregatorNotSet();

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/* --------------------- *
 *  Cross Margin Errors
 * --------------------- */

/// @dev cross margin doesn't support this action
error CM_UnsupportedAction();

/// @dev cannot override a non-empty subaccount id
error CM_AccountIsNotEmpty();

/// @dev unsupported token type
error CM_UnsupportedTokenType();

/// @dev can only add long tokens that are not expired
error CM_Option_Expired();

/// @dev can only add long tokens from authorized engines
error CM_Not_Authorized_Engine();

/// @dev collateral id is wrong: the id doesn't match the existing collateral
error CM_WrongCollateralId();

/// @dev invalid collateral:
error CM_CannotMintOptionWithThisCollateral();

/// @dev invalid tokenId specify to mint / burn actions
error CM_InvalidToken();

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SafeCast} from "lib/grappa/lib/openzeppelin-contracts/contracts/utils/math/SafeCast.sol";

library ArrayUtil {
    using SafeCast for uint256;
    using SafeCast for int256;

    error IndexOutOfBounds();

    /**
     * @dev Returns minimal element in array
     * @return m
     */
    function min(int256[] memory x) internal pure returns (int256 m) {
        m = x[0];
        for (uint256 i; i < x.length;) {
            if (x[i] < m) {
                m = x[i];
            }
            unchecked {
                ++i;
            }
        }
    }

    function min(uint256[] memory x) internal pure returns (uint256 m) {
        m = x[0];
        for (uint256 i; i < x.length;) {
            if (x[i] < m) {
                m = x[i];
            }
            unchecked {
                ++i;
            }
        }
    }

    function minMax(uint256[] memory x) internal pure returns (uint256 min_, uint256 max_) {
        (min_, max_) = (x[0], x[0]);
        for (uint256 i; i < x.length;) {
            if (x[i] < min_) {
                min_ = x[i];
            }
            if (x[i] > max_) {
                max_ = x[i];
            }
            unchecked {
                ++i;
            }
        }
    }

    // /**
    //  * @dev Returns minimal element's index
    //  * @return m
    //  */
    // function imin(uint256[] memory x) internal pure returns (uint256 m) {
    //     m = 0;
    //     for (uint256 i; i < x.length; i++) {
    //         if (x[i] < x[m]) {
    //             m = i;
    //         }
    //     }
    //     return m;
    // }

    /**
     * @dev Returns maximal element in array
     * @return m
     */
    function max(int256[] memory x) internal pure returns (int256 m) {
        m = x[0];
        for (uint256 i; i < x.length; i++) {
            if (x[i] > m) {
                m = x[i];
            }
        }
    }

    function max(uint256[] memory x) internal pure returns (uint256 m) {
        m = x[0];
        for (uint256 i; i < x.length; i++) {
            if (x[i] > m) {
                m = x[i];
            }
        }
    }

    /**
     * @dev Returns maximal elements comparedTo value
     * @return y array
     */
    function maximum(int256[] memory x, int256 z) internal pure returns (int256[] memory y) {
        y = new int256[](x.length);
        for (uint256 i; i < x.length; i++) {
            if (x[i] > z) y[i] = x[i];
            else y[i] = z;
        }
    }

    // /**
    //  * @dev Returns maximal element's index
    //  * @return m maximal
    //  */
    // function imax(uint256[] memory x) internal pure returns (uint256 m) {
    //     for (uint256 i; i < x.length; i++) {
    //         if (x[i] > x[m]) {
    //             m = i;
    //         }
    //     }
    // }

    /**
     * @dev Removes element at index in a new unsigned int array, does not change x memory in place
     * @return y new array
     */
    function remove(uint256[] memory x, uint256 z) internal pure returns (uint256[] memory y) {
        if (z >= x.length) return x;
        y = new uint256[](x.length - 1);
        for (uint256 i; i < x.length;) {
            if (i < z) y[i] = x[i];
            else if (i > z) y[i - 1] = x[i];
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Removes element at index in a new signed int array, does not change x memory in place
     * @return y new array
     */
    function remove(int256[] memory x, uint256 z) internal pure returns (int256[] memory y) {
        if (z >= x.length) return x;
        y = new int256[](x.length - 1);
        for (uint256 i; i < x.length;) {
            if (i < z) y[i] = x[i];
            else if (i > z) y[i - 1] = x[i];
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Returns index of element
     * @return found
     * @return index
     */
    function indexOf(int256[] memory x, int256 v) internal pure returns (bool, uint256) {
        for (uint256 i; i < x.length;) {
            if (x[i] == v) {
                return (true, i);
            }
            unchecked {
                ++i;
            }
        }
        return (false, 0);
    }

    function indexOf(bytes32[] memory x, bytes32 v) internal pure returns (bool, uint256) {
        for (uint256 i; i < x.length;) {
            if (x[i] == v) {
                return (true, i);
            }
            unchecked {
                ++i;
            }
        }
        return (false, 0);
    }

    function indexOf(uint256[] memory x, uint256 v) internal pure returns (bool, uint256) {
        for (uint256 i; i < x.length;) {
            if (x[i] == v) {
                return (true, i);
            }
            unchecked {
                ++i;
            }
        }
        return (false, 0);
    }

    /**
     * @dev Compute sum of all elements
     * @return s sum
     */
    function sum(int256[] memory x) internal pure returns (int256 s) {
        for (uint256 i; i < x.length;) {
            s += x[i];
            unchecked {
                ++i;
            }
        }
    }

    function sum(uint256[] memory x) internal pure returns (uint256 s) {
        for (uint256 i; i < x.length;) {
            s += x[i];
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev put the min of last p elements in array at position p.
     */

    function argSort(uint256[] memory x) internal pure returns (uint256[] memory y, uint256[] memory ixArray) {
        ixArray = new uint256[](x.length);
        // fill in index array
        for (uint256 i; i < x.length;) {
            ixArray[i] = i;
            unchecked {
                ++i;
            }
        }
        // initialize copy of x
        y = new uint256[](x.length);
        populate(y, x, 0);
        // sort
        quickSort(y, int256(0), int256(y.length - 1), ixArray);
    }

    function sort(uint256[] memory x) internal pure returns (uint256[] memory y) {
        y = new uint256[](x.length);
        populate(y, x, 0);
        quickSort(y, int256(0), int256(y.length - 1));
    }

    /*
    @dev quicksort implementation, sorts arr input IN PLACE
    */
    function quickSort(uint256[] memory arr, int256 left, int256 right) internal pure {
        if (left == right) return;
        int256 i = left;
        int256 j = right;
        uint256 pivot = arr[uint256(left + (right - left) / 2)];
        while (i <= j) {
            while (arr[uint256(i)] < pivot) {
                unchecked {
                    ++i;
                }
            }
            while (pivot < arr[uint256(j)]) {
                unchecked {
                    --j;
                }
            }
            if (i <= j) {
                (arr[uint256(i)], arr[uint256(j)]) = (arr[uint256(j)], arr[uint256(i)]);
                unchecked {
                    ++i;
                    --j;
                }
            }
        }
        if (left < j) quickSort(arr, left, j);
        if (i < right) quickSort(arr, i, right);
    }

    /*
    @dev quicksort implementation with indexes, sorts input arr and indexArray IN PLACE
    */
    function quickSort(uint256[] memory arr, int256 left, int256 right, uint256[] memory indexArray) internal pure {
        if (left == right) return;
        int256 i = left;
        int256 j = right;
        uint256 pivot = arr[uint256(left + (right - left) / 2)];
        unchecked {
            while (i <= j) {
                while (arr[uint256(i)] < pivot) {
                    ++i;
                }
                while (pivot < arr[uint256(j)]) {
                    --j;
                }
                if (i <= j) {
                    (arr[uint256(i)], arr[uint256(j)]) = (arr[uint256(j)], arr[uint256(i)]);
                    (indexArray[uint256(i)], indexArray[uint256(j)]) = (indexArray[uint256(j)], indexArray[uint256(i)]);
                    ++i;
                    --j;
                }
            }
            if (left < j) quickSort(arr, left, j, indexArray);
            if (i < right) quickSort(arr, i, right, indexArray);
        }
    }

    /**
     *  sort functions for int ***
     */

    function argSort(int256[] memory x) internal pure returns (int256[] memory y, uint256[] memory ixArray) {
        ixArray = new uint256[](x.length);
        // fill in index array
        for (uint256 i; i < x.length;) {
            ixArray[i] = i;
            unchecked {
                ++i;
            }
        }
        // initialize copy of x
        y = new int256[](x.length);
        populate(y, x, 0);
        // sort
        quickSort(y, int256(0), int256(y.length - 1), ixArray);
    }

    function sort(int256[] memory x) internal pure returns (int256[] memory y) {
        y = new int256[](x.length);
        populate(y, x, 0);
        quickSort(y, int256(0), int256(y.length - 1));
    }

    // quicksort implementation, sorts arr in place
    function quickSort(int256[] memory arr, int256 left, int256 right) internal pure {
        if (left == right) return;
        int256 i = left;
        int256 j = right;
        int256 pivot = arr[uint256(left + (right - left) / 2)];
        while (i <= j) {
            while (arr[uint256(i)] < pivot) {
                unchecked {
                    ++i;
                }
            }
            while (pivot < arr[uint256(j)]) {
                unchecked {
                    --j;
                }
            }
            if (i <= j) {
                (arr[uint256(i)], arr[uint256(j)]) = (arr[uint256(j)], arr[uint256(i)]);
                unchecked {
                    ++i;
                    --j;
                }
            }
        }
        if (left < j) quickSort(arr, left, j);
        if (i < right) quickSort(arr, i, right);
    }

    // quicksort implementation with indexes, sorts arr and indexArray in place
    function quickSort(int256[] memory arr, int256 left, int256 right, uint256[] memory indexArray) internal pure {
        if (left == right) return;
        int256 i = left;
        int256 j = right;
        int256 pivot = arr[uint256(left + (right - left) / 2)];
        while (i <= j) {
            while (arr[uint256(i)] < pivot) {
                unchecked {
                    ++i;
                }
            }
            while (pivot < arr[uint256(j)]) {
                unchecked {
                    --j;
                }
            }
            if (i <= j) {
                (arr[uint256(i)], arr[uint256(j)]) = (arr[uint256(j)], arr[uint256(i)]);
                (indexArray[uint256(i)], indexArray[uint256(j)]) = (indexArray[uint256(j)], indexArray[uint256(i)]);
                unchecked {
                    ++i;
                    --j;
                }
            }
        }
        if (left < j) quickSort(arr, left, j, indexArray);
        if (i < right) quickSort(arr, i, right, indexArray);
    }

    /**
     * End Sort Functions for Int ******
     */

    function sortByIndexes(int256[] memory x, uint256[] memory z) internal pure returns (int256[] memory y) {
        y = new int256[](x.length);
        for (uint256 i; i < x.length; i++) {
            y[i] = x[z[i]];
        }
    }

    function append(bytes32[] memory x, bytes32 e) internal pure returns (bytes32[] memory y) {
        y = new bytes32[](x.length + 1);
        uint256 i;
        for (i = 0; i < x.length; i++) {
            y[i] = x[i];
        }
        y[i] = e;
    }

    function append(int256[] memory x, int256 v) internal pure returns (int256[] memory y) {
        y = new int256[](x.length + 1);
        uint256 i;
        for (i = 0; i < x.length;) {
            y[i] = x[i];
            unchecked {
                ++i;
            }
        }
        y[i] = v;
    }

    function append(uint256[] memory x, uint256 v) internal pure returns (uint256[] memory y) {
        y = new uint256[](x.length + 1);
        uint256 i;
        for (i = 0; i < x.length;) {
            y[i] = x[i];
            unchecked {
                ++i;
            }
        }
        y[i] = v;
    }

    function concat(int256[] memory a, int256[] memory b) internal pure returns (int256[] memory y) {
        y = new int256[](a.length + b.length);
        uint256 v;
        uint256 i;
        for (i; i < a.length;) {
            y[v] = a[i];
            unchecked {
                ++i;
                ++v;
            }
        }
        for (i = 0; i < b.length;) {
            y[v] = b[i];
            unchecked {
                ++i;
                ++v;
            }
        }
    }

    function concat(uint256[] memory a, uint256[] memory b) internal pure returns (uint256[] memory y) {
        y = new uint256[](a.length + b.length);
        uint256 v;
        uint256 i;
        for (i; i < a.length;) {
            y[v] = a[i];
            unchecked {
                ++i;
                ++v;
            }
        }
        for (i = 0; i < b.length;) {
            y[v] = b[i];
            unchecked {
                ++i;
                ++v;
            }
        }
    }

    /*
    @dev this function modifies memory x IN PLACE. Fills x with value v
    */
    function fill(int256[] memory x, int256 v) internal pure {
        for (uint256 i = 0; i < x.length; i++) {
            x[i] = v;
        }
    }

    /*
    @dev modifies memory a IN PLACE. Populates a starting at index z with values from b.
    */
    function populate(uint256[] memory a, uint256[] memory b, uint256 z) internal pure {
        for (uint256 i = 0; i < a.length; i++) {
            a[z + i] = b[i];
        }
    }

    /*
    @dev modifies memory a IN PLACE. Populates a starting at index z with values from b.
    */
    function populate(int256[] memory a, int256[] memory b, uint256 z) internal pure {
        for (uint256 i = 0; i < a.length; i++) {
            a[z + i] = b[i];
        }
    }

    function at(int256[] memory x, int256 i) internal pure returns (int256) {
        int256 len = x.length.toInt256();
        if (i > 0) {
            if (i > len) revert IndexOutOfBounds();
            return x[uint256(i)];
        } else {
            if (i < -len) revert IndexOutOfBounds();
            return x[(len + i).toUint256()];
        }
    }

    function at(uint256[] memory x, int256 i) internal pure returns (uint256) {
        int256 len = x.length.toInt256();
        if (i > 0) {
            if (i > len) revert IndexOutOfBounds();
            return x[uint256(i)];
        } else {
            if (i < -len) revert IndexOutOfBounds();
            return x[(len + i).toUint256()];
        }
    }

    function slice(int256[] memory x, int256 _start, int256 _end) internal pure returns (int256[] memory a) {
        int256 len = x.length.toInt256();
        if (_start < 0) _start = len + _start;
        if (_end <= 0) _end = len + _end;
        if (_end < _start) return new int256[](0);

        uint256 start = _start.toUint256();
        uint256 end = _end.toUint256();

        a = new int256[](end - start);
        uint256 y = 0;
        for (uint256 i = start; i < end;) {
            a[y] = x[i];
            unchecked {
                ++i;
                ++y;
            }
        }
    }

    function subEachFrom(uint256[] memory x, uint256 z) internal pure returns (int256[] memory y) {
        y = new int256[](x.length);
        for (uint256 i = 0; i < x.length; i++) {
            y[i] = z.toInt256() - x[i].toInt256();
        }
    }

    function subEachBy(uint256[] memory x, uint256 z) internal pure returns (int256[] memory y) {
        y = new int256[](x.length);
        for (uint256 i = 0; i < x.length; i++) {
            y[i] = x[i].toInt256() - z.toInt256();
        }
    }

    function addEachBy(int256[] memory x, int256 z) internal pure returns (int256[] memory y) {
        y = new int256[](x.length);
        for (uint256 i = 0; i < x.length; i++) {
            y[i] = x[i] + z;
        }
    }

    function add(int256[] memory a, int256[] memory b) internal pure returns (int256[] memory y) {
        y = new int256[](a.length);
        for (uint256 i = 0; i < a.length; i++) {
            y[i] = a[i] + b[i];
        }
    }

    function eachMulDivDown(int256[] memory x, int256 z, int256 d) internal pure returns (int256[] memory y) {
        y = new int256[](x.length);
        for (uint256 i = 0; i < x.length; i++) {
            y[i] = (x[i] * z) / d;
        }
    }

    function eachMulDivUp(int256[] memory x, int256 z, int256 d) internal pure returns (int256[] memory y) {
        y = new int256[](x.length);
        for (uint256 i = 0; i < x.length; i++) {
            y[i] = ((x[i] * z) / d) + 1;
        }
    }

    function eachMul(int256[] memory x, int256 z) internal pure returns (int256[] memory y) {
        y = new int256[](x.length);
        for (uint256 i = 0; i < x.length; i++) {
            y[i] = x[i] * z;
        }
    }

    function eachDiv(int256[] memory x, int256 z) internal pure returns (int256[] memory y) {
        y = new int256[](x.length);
        for (uint256 i = 0; i < x.length; i++) {
            y[i] = x[i] / z;
        }
    }

    function dot(int256[] memory a, int256[] memory b) internal pure returns (int256 s) {
        for (uint256 i = 0; i < a.length; i++) {
            s += a[i] * b[i];
        }
    }

    function dot(uint256[] memory a, int256[] memory b) internal pure returns (int256 s) {
        for (uint256 i = 0; i < a.length; i++) {
            s += int256(a[i]) * b[i];
        }
    }

    /**
     * @dev converting array of variable types
     */

    function toInt256(uint256[] memory x) internal pure returns (int256[] memory y) {
        y = new int256[](x.length);
        for (uint256 i = 0; i < x.length; i++) {
            y[i] = x[i].toInt256();
        }
    }

    function toUint256(int256[] memory x) internal pure returns (uint256[] memory y) {
        y = new uint256[](x.length);
        for (uint256 i = 0; i < x.length; i++) {
            y[i] = x[i].toUint256();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.4.1) (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248) {
        require(value >= type(int248).min && value <= type(int248).max, "SafeCast: value doesn't fit in 248 bits");
        return int248(value);
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240) {
        require(value >= type(int240).min && value <= type(int240).max, "SafeCast: value doesn't fit in 240 bits");
        return int240(value);
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232) {
        require(value >= type(int232).min && value <= type(int232).max, "SafeCast: value doesn't fit in 232 bits");
        return int232(value);
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224) {
        require(value >= type(int224).min && value <= type(int224).max, "SafeCast: value doesn't fit in 224 bits");
        return int224(value);
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216) {
        require(value >= type(int216).min && value <= type(int216).max, "SafeCast: value doesn't fit in 216 bits");
        return int216(value);
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208) {
        require(value >= type(int208).min && value <= type(int208).max, "SafeCast: value doesn't fit in 208 bits");
        return int208(value);
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200) {
        require(value >= type(int200).min && value <= type(int200).max, "SafeCast: value doesn't fit in 200 bits");
        return int200(value);
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192) {
        require(value >= type(int192).min && value <= type(int192).max, "SafeCast: value doesn't fit in 192 bits");
        return int192(value);
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184) {
        require(value >= type(int184).min && value <= type(int184).max, "SafeCast: value doesn't fit in 184 bits");
        return int184(value);
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176) {
        require(value >= type(int176).min && value <= type(int176).max, "SafeCast: value doesn't fit in 176 bits");
        return int176(value);
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168) {
        require(value >= type(int168).min && value <= type(int168).max, "SafeCast: value doesn't fit in 168 bits");
        return int168(value);
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160) {
        require(value >= type(int160).min && value <= type(int160).max, "SafeCast: value doesn't fit in 160 bits");
        return int160(value);
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152) {
        require(value >= type(int152).min && value <= type(int152).max, "SafeCast: value doesn't fit in 152 bits");
        return int152(value);
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144) {
        require(value >= type(int144).min && value <= type(int144).max, "SafeCast: value doesn't fit in 144 bits");
        return int144(value);
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136) {
        require(value >= type(int136).min && value <= type(int136).max, "SafeCast: value doesn't fit in 136 bits");
        return int136(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120) {
        require(value >= type(int120).min && value <= type(int120).max, "SafeCast: value doesn't fit in 120 bits");
        return int120(value);
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112) {
        require(value >= type(int112).min && value <= type(int112).max, "SafeCast: value doesn't fit in 112 bits");
        return int112(value);
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104) {
        require(value >= type(int104).min && value <= type(int104).max, "SafeCast: value doesn't fit in 104 bits");
        return int104(value);
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96) {
        require(value >= type(int96).min && value <= type(int96).max, "SafeCast: value doesn't fit in 96 bits");
        return int96(value);
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88) {
        require(value >= type(int88).min && value <= type(int88).max, "SafeCast: value doesn't fit in 88 bits");
        return int88(value);
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80) {
        require(value >= type(int80).min && value <= type(int80).max, "SafeCast: value doesn't fit in 80 bits");
        return int80(value);
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72) {
        require(value >= type(int72).min && value <= type(int72).max, "SafeCast: value doesn't fit in 72 bits");
        return int72(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56) {
        require(value >= type(int56).min && value <= type(int56).max, "SafeCast: value doesn't fit in 56 bits");
        return int56(value);
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48) {
        require(value >= type(int48).min && value <= type(int48).max, "SafeCast: value doesn't fit in 48 bits");
        return int48(value);
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40) {
        require(value >= type(int40).min && value <= type(int40).max, "SafeCast: value doesn't fit in 40 bits");
        return int40(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24) {
        require(value >= type(int24).min && value <= type(int24).max, "SafeCast: value doesn't fit in 24 bits");
        return int24(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { ArrayUtil } from "../../lib/grappa/src/libraries/ArrayUtil.sol";

import "../utils/Error.sol";

/// @notice a special queue struct for auction mechanics
library BatchAuctionQ {
    struct Queue {
        int256 clearingPrice;
        ///@notice array of bid prices in time order
        int256[] bidPriceList;
        ///@notice array of bid quantities in time order
        uint256[] bidQuantityList;
        ///@notice array of bidders
        address[] bidOwnerList;
        ///@notice winning bids
        uint256[] filledAmount;
    }

    function isEmpty(Queue storage self) external view returns (bool) {
        return self.bidPriceList.length == 0;
    }

    ///@notice insert bid in heap
    function insert(
        Queue storage self,
        address owner,
        int256 price,
        uint256 quantity
    ) external {
        self.bidPriceList.push(price);
        self.bidQuantityList.push(quantity);
        self.bidOwnerList.push(owner);
        self.filledAmount.push(0);
    }

    /// @notice remove deletes the owner from the owner list, so checking for a 0 address checks that a bid was pulled
    function remove(Queue storage self, uint256 index) external {
        delete self.bidOwnerList[index];
        delete self.bidQuantityList[index];
        delete self.bidPriceList[index];
        delete self.filledAmount[index];
    }

    /**
     * @notice fills as many bids as possible at the highest price as possible, the lowest price bid that was filled should become the clearing price
     */
    function computeFills(Queue storage self, uint256 totalSize)
        external
        returns (int256 clearingPrice, uint256 totalFilled)
    {
        uint256 bidLength = self.bidQuantityList.length;

        if (bidLength == 0) return (0, 0);

        if (ArrayUtil.sum(self.bidQuantityList) == 0) return (0, 0);

        uint256 bidId;
        uint256 bidQuantity;
        uint256 orderFilled;

        // sort the bids by price and return an array of indices
        (, uint256[] memory bidOrder) = ArrayUtil.argSort(self.bidPriceList);

        // start from back of list to reverse sort
        uint256 i = bidLength - 1;
        bool endOfBids = false;

        while (totalFilled < totalSize && !endOfBids) {
            bidId = bidOrder[i];

            endOfBids = i == 0;

            // decrease index here, do not use i after this
            unchecked {
                --i;
            }

            // if this bid was removed, skip it
            if (self.bidOwnerList[bidId] == address(0)) continue;

            bidQuantity = self.bidQuantityList[bidId];

            //check if we can only partly fill a bid
            if ((totalFilled + bidQuantity) > totalSize) orderFilled = totalSize - totalFilled;
            else orderFilled = bidQuantity;

            self.filledAmount[bidId] = orderFilled;

            totalFilled += orderFilled;
        }

        self.clearingPrice = clearingPrice = self.bidPriceList[bidId];
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.4;

import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { Vault } from "../../libraries/Vault.sol";
import { HashnoteVault } from "./base/HashnoteVault.sol";
import { HashnoteOptionsVaultStorage } from "../../storage/HashnoteOptionsVaultStorage.sol";
import { VaultLifecycle } from "../../libraries/VaultLifecycle.sol";
import { ShareMath } from "../../libraries/ShareMath.sol";
import { IVaultPauser } from "../../interfaces/IVaultPauser.sol";
import "../../utils/Error.sol";

/**
 * UPGRADEABILITY: Since we use the upgradeable proxy pattern, we must observe
 * the inheritance chain closely.
 * Any changes/appends in storage variable needs to happen in HashnoteOptionsVaultStorage.
 * HashnoteOptionsVault should not inherit from any other contract aside from HashnoteVault, HashnoteOptionsVaultStorage
 */
contract HashnoteOptionsVault is HashnoteVault, HashnoteOptionsVaultStorage {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using ShareMath for Vault.DepositReceipt;

    /************************************************
     *  IMMUTABLES & CONSTANTS
     ***********************************************/

    // The minimum duration for an option auction.
    uint256 private constant MIN_AUCTION_DURATION = 5 minutes;

    // MARGIN_ENGINE is Grappa protocol's collateral pool.
    // https://github.com/antoncoding/grappa/blob/master/src/core/engines
    address public immutable MARGIN_ENGINE;

    // BATCH_AUCTION
    address public immutable BATCH_AUCTION;

    /************************************************
     *  EVENTS
     ***********************************************/

    event OpenOptions(uint256[] indexed options, uint256 depositAmount, address indexed manager);

    event CloseOptions(uint256[] indexed options, uint80 withdrawAmount, address indexed manager);

    event NewOptionStrikeSelected(uint256 strikePrice);

    /************************************************
     *  CONSTRUCTOR & INITIALIZATION
     ***********************************************/

    /**
     * @notice Initializes the contract with immutable variables
     * @param _marginEngine is the contract address for providing collateral to grappa
     * @param _batchAuction is the contract address that facilitates gnosis auctions
     */
    constructor(address _marginEngine, address _batchAuction) HashnoteVault() {
        if (_marginEngine == address(0) || _batchAuction == address(0)) revert HTV_BadAddress();

        MARGIN_ENGINE = _marginEngine;
        BATCH_AUCTION = _batchAuction;
    }

    /**
     * @notice Initializes the OptionVault contract with storage variables.
     * @param _initParams is the struct with vault initialization parameters
     * @param _vaultParams is the struct with vault general data
     */
    function initialize(
        Vault.InitParams calldata _initParams,
        Vault.VaultParams calldata _vaultParams
    ) external initializer {
        baseInitialize(_initParams, _vaultParams);
        if (_initParams._leverageRatio == 0) revert HTV_BadLevRatio();
        if (
            _initParams._auctionDuration < MIN_AUCTION_DURATION ||
            _initParams._auctionDuration >= _initParams._roundConfig.duration
        ) revert HTV_BadDuration();

        auctionDuration = _initParams._auctionDuration;
        leverageRatio = _initParams._leverageRatio;
    }

    /************************************************
     *  SETTERS
     ***********************************************/

    /**
     * @notice Sets the new auction duration
     * @param newAuctionDuration is the auction duration
     */
    function setAuctionDuration(uint256 newAuctionDuration) external {
        _onlyOwner();

        if (newAuctionDuration < MIN_AUCTION_DURATION || newAuctionDuration >= roundConfig.duration)
            revert HTV_BadDuration();

        auctionDuration = newAuctionDuration;
    }

    /**
     * @notice Sets oToken Premium
     * @param premium is new premium expected to receive/pay for each structure (scale of 10**18)
     */
    function setPremium(int256 premium) external {
        _onlyKeeper();

        optionState.premium = premium;
    }

    /************************************************
     *  VAULT OPERATIONS
     ***********************************************/

    /**
     * @notice Closes the existing short and calculate the shares to mint, new price per share &
      amount of funds to re-allocate as collateral for the new round
     * Since we are incrementing the round here, the options are sold in the beginning of a round
     * instead of at the end of the round. For example, at round 1, we don't sell any options. We
     * start selling options at the beginning of round 2.
     */
    function closeRound() external nonReentrant {
        uint256[] memory oldOptions = optionState.currentOptions;

        if (oldOptions.length == 0 && vaultState.round > 1) revert HTV_RoundClosed();

        _closeShort(oldOptions);

        _closeRound();

        // process pending withdraws
        uint128 queuedWithdrawShares = vaultState.queuedWithdrawShares;

        vaultState.queuedWithdrawShares = 0;

        if (queuedWithdrawShares > 0) IVaultPauser(vaultPauser).processVaultWithdraw(address(this));

        // Get current balance after all withdraws
        uint256 currentBalance = IERC20(collaterals[0].addr).balanceOf(address(this));

        ShareMath.assertUint104(currentBalance);
        vaultState.lockedAmount = uint104(currentBalance);
    }

    /**
     * @notice Closes the existing short position for the vault.
     */
    function _closeShort(uint256[] memory optionTokens) internal {
        if (optionTokens.length != 0) {
            uint256 optionTokenId = optionTokens[0];

            if (!VaultLifecycle.isOptionExpired(optionTokenId)) revert HTV_OptionNotExpired();

            uint256 lockedAmount = vaultState.lockedAmount;
            vaultState.lastLockedAmount = uint104(lockedAmount);
        }

        vaultState.lockedAmount = 0;
        optionState.premium = 0;
        optionState.maxStructures = 0;
        optionState.mintedStructures = 0;
        delete optionState.currentOptions;

        if (optionTokens.length > 0) {
            //uint256 withdrawAmount =
            VaultLifecycle.settleOptions(MARGIN_ENGINE);

            // emit CloseOptions(optionTokens, withdrawAmount, msg.sender);

            // TODO: figure out better way
            // for (uint256 i = 0; i < optionTokens.length; i++) {
            //     uint256 optionTokenId = optionTokens[i];

            //
            // }
        }
    }

    /**
     * @notice Sets the next option the vault will be shorting
     * @param newStrikes new strikes for each instruments
     * @param premium new premium expected to receive/pay for each structure (scale of 10**18)
     */
    function commitNextOption(
        uint256[] calldata newStrikes,
        uint256 maxStructures,
        int256 premium,
        uint256[] memory vault,
        uint256[] memory counterparty
    ) external {
        _onlyKeeper();

        if (newStrikes.length != instruments.length) revert HTV_BadNumStrikes();

        uint256 currentOptionsLength = optionState.currentOptions.length;
        uint256 currentRound = vaultState.round;

        if (currentOptionsLength > 0 || currentRound == 1) revert HTV_RoundNotClosed();
        if (vault.length != collaterals.length) revert HTV_BadCollaterals();

        (uint256[] memory tokenIds, uint256 expiry) = VaultLifecycle.commitNextOption(
            MARGIN_ENGINE,
            newStrikes,
            instruments,
            roundConfig
        );

        optionState.nextOptions = tokenIds;
        optionState.maxStructures = maxStructures;
        optionState.premium = premium;
        optionState.vault = vault;
        optionState.counterparty = counterparty;

        roundExpiry[currentRound] = expiry;

        // TODO
        // emit NewOptionStrikeSelected(newStrikes, premium, amount);
    }

    function setRoundCollateralAmounts(uint256[] memory amounts, bool isVault) external {
        _onlyKeeper();

        if (optionState.currentOptions.length != 0) revert HTV_ActiveRound();

        if (isVault) optionState.vault = amounts;
        else optionState.counterparty = amounts;

        if (isVault && vaultState.round == 1) roundStartingBalances[1] = amounts;
    }

    function rebalance(address otc, uint256[] calldata amounts) external nonReentrant {
        _onlyKeeper();

        VaultLifecycle.rebalance(otc, amounts, collaterals, optionState.vault, whitelist);
    }

    /**
     * @notice Rolls the vault's funds into a new short position and create a new offer.
     */
    function rollToNextOption() external {
        _onlyKeeper();

        if (optionState.nextOptions.length == 0) revert HTV_BadOption();
        if (optionAuctionId != 0) revert HTV_AuctionInProgress();

        if (optionState.maxStructures - optionState.mintedStructures > 0) _startAuction();
    }

    /**
     * @notice Initiate the batch auction.
     */
    function startAuction() external {
        _onlyKeeper();

        _startAuction();
    }

    function _startAuction() internal {
        if (optionAuctionId > 0) revert HTV_AuctionInProgress();

        uint256 structures = optionState.maxStructures;
        unchecked {
            structures -= optionState.mintedStructures;
        }

        if (structures == 0) revert HTV_BadStructures();

        uint256[] memory optionTokens = optionState.currentOptions;
        if (optionTokens.length == 0) optionTokens = optionState.nextOptions;

        if (optionTokens.length == 0) revert HTV_BadOption();

        VaultLifecycle.AuctionParams memory params;
        params.auctionAddr = BATCH_AUCTION;
        params.biddingToken = collaterals[0].addr;
        params.collaterals = collaterals;
        params.counterparty = optionState.counterparty;
        params.duration = auctionDuration;
        params.engineAddr = MARGIN_ENGINE;
        params.maxStructures = optionState.maxStructures;
        params.optionTokens = optionTokens;
        params.premium = optionState.premium;
        params.structures = structures;
        params.whitelist = whitelist;

        optionAuctionId = VaultLifecycle.startAuction(params);
    }

    function settleAuction() external nonReentrant {
        _onlyKeeper();

        optionState.currentOptions = optionState.nextOptions;
        optionState.nextOptions = new uint256[](0);

        // uint256 lockedBalance = vaultState.lockedAmount;
        // TODO
        // emit OpenOptions(newOptions, lockedBalance, msg.sender);

        (, uint256 structuresSold) = VaultLifecycle.settleAuction(BATCH_AUCTION, optionAuctionId);

        if (structuresSold > 0) {
            VaultLifecycle.CreateStructuresParams memory params;
            params.engineAddr = MARGIN_ENGINE;
            params.instruments = instruments;
            params.optionTokens = optionState.currentOptions;
            params.structuresToMint = structuresSold;
            params.maxStructures = optionState.maxStructures;
            params.collaterals = collaterals;
            params.vault = optionState.vault;
            params.counterparty = optionState.counterparty;

            VaultLifecycle.createStructures(params);

            unchecked {
                optionState.mintedStructures += structuresSold;
            }
        }

        optionAuctionId = 0;
    }

    function novate(
        address recipient,
        uint256 amount,
        uint256[] calldata options,
        uint256[] calldata counterparty
    ) external nonReentrant {
        if (msg.sender != BATCH_AUCTION) revert HTV_Unauthorized();

        VaultLifecycle.novate(MARGIN_ENGINE, instruments, options, collaterals, counterparty, recipient, amount);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.4;

import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { FixedPointMathLib } from "solmate/src/utils/FixedPointMathLib.sol";

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { ERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import { Vault } from "../../../libraries/Vault.sol";
import { VaultLifecycle } from "../../../libraries/VaultLifecycle.sol";
import { ShareMath } from "../../../libraries/ShareMath.sol";

import { IVaultPauser } from "../../../interfaces/IVaultPauser.sol";
import { IWhitelist } from "../../../interfaces/IWhitelist.sol";

import "../../../utils/Error.sol";

contract HashnoteVault is OwnableUpgradeable, ERC20Upgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using ShareMath for Vault.DepositReceipt;

    /************************************************
     *  IMMUTABLES & CONSTANTS
     ***********************************************/

    /************************************************
     *  NON UPGRADEABLE STORAGE
     ***********************************************/

    /// @notice Stores the user's pending deposit for the round
    mapping(address => Vault.DepositReceipt) public depositReceipts;

    /// @notice On every round's close, the pricePerShare value of an hnVault token is stored
    /// This is used to determine the number of shares to be returned
    /// to a user with their DepositReceipt.depositAmount
    mapping(uint256 => uint256) public roundPricePerShare;

    /// @notice deposit asset amounts round => collateralBalances[]
    mapping(uint256 => uint256[]) public roundStartingBalances;

    /// @notice expiry of each, used for NAV round => expiry timestamp
    mapping(uint256 => uint256) public roundExpiry;

    /// @notice Stores pending user withdrawals
    mapping(address => Vault.Withdrawal) public withdrawals;

    /// @notice Vault's parameters like cap
    Vault.VaultParams public vaultParams;

    /// Linear combination of options
    Vault.Instrument[] public instruments;

    /// Linear combination of options
    Vault.Collateral[] public collaterals;

    /// @notice Vault's lifecycle state like round and locked amounts
    Vault.VaultState public vaultState;

    /// @notice Vault's state of the options sold
    Vault.OptionState public optionState;

    /// @notice Vault's round configuration
    Vault.RoundConfig public roundConfig;

    // Oracle addres to caculcate NAV (shareprice)
    address public oracle;

    /// @notice Fee recipient for the performance and management fees
    address public feeRecipient;

    /// @notice role in charge of weekly vault operations such as commitAndClose, rollToNextOption and burnRemainingOTokens
    // no access to critical vault changes
    address public keeper;

    /// @notice Performance fee charged on premiums earned in rollToNextOption. Only charged when there is no loss.
    uint256 public performanceFee;

    /// @notice Management fee charged on entire AUM in rollToNextOption. Only charged when there is no loss.
    uint256 public managementFee;

    /// @notice Vault Pauser Contract for the vault
    address public vaultPauser;

    /// @notice Whitelist contract, checks permissions and sanctions
    address public whitelist;

    // Gap is left to avoid storage collisions. Though HashnoteVault is not upgradeable, we add this as a safety measure.
    uint256[5] private ____gap;

    // *IMPORTANT* NO NEW STORAGE VARIABLES SHOULD BE ADDED HERE
    // This is to prevent storage collisions. All storage variables should be appended to HashnoteOptionsVaultStorage
    // or HashnoteDeltaVaultStorage instead. Read this documentation to learn more:
    // https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#modifying-your-contracts

    /************************************************
     *  EVENTS
     ***********************************************/

    event Deposit(address indexed account, uint256 amount, uint256 round);

    event InstantWithdraw(address indexed account, uint256 amount, uint256 round);

    event InitiateWithdraw(address indexed account, uint256 shares, uint256 round);

    event Redeem(address indexed account, uint256 share, uint256 round);

    event ManagementFeeSet(uint256 managementFee, uint256 newManagementFee);

    event PerformanceFeeSet(uint256 performanceFee, uint256 newPerformanceFee);

    event CapSet(uint256 oldCap, uint256 newCap);

    event Withdraw(address indexed account, uint256 amount, uint256 shares);

    event CollectVaultFees(uint256 performanceFee, uint256 vaultFee, uint256 round, address indexed feeRecipient);

    /************************************************
     *  CONSTRUCTOR & INITIALIZATION
     ***********************************************/

    /**
     * @notice Initializes the contract with immutable variables
     */
    constructor() {}

    /**
     * @notice Initializes the OptionVault contract with storage variables.
     */
    function baseInitialize(
        Vault.InitParams calldata _initParams,
        Vault.VaultParams calldata _vaultParams
    ) internal initializer {
        VaultLifecycle.verifyInitializerParams(_initParams, _vaultParams);

        __ReentrancyGuard_init();
        __ERC20_init(_initParams._tokenName, _initParams._tokenSymbol);
        __Ownable_init();
        transferOwnership(_initParams._owner);

        keeper = _initParams._keeper;

        oracle = _initParams._oracle;
        feeRecipient = _initParams._feeRecipient;
        performanceFee = _initParams._performanceFee;
        managementFee = _initParams._managementFee;
        vaultPauser = _initParams._vaultPauser;
        vaultParams = _vaultParams;
        roundConfig = _initParams._roundConfig;

        uint256 i;
        for (i; i < _initParams._instruments.length; ) {
            instruments.push(_initParams._instruments[i]);

            unchecked {
                ++i;
            }
        }

        for (i = 0; i < _initParams._collaterals.length; ) {
            collaterals.push(_initParams._collaterals[i]);

            unchecked {
                ++i;
            }
        }

        uint256 collateralBalance = IERC20(collaterals[0].addr).balanceOf(address(this));
        ShareMath.assertUint104(collateralBalance);
        vaultState.lastLockedAmount = uint104(collateralBalance);

        vaultState.round = 1;
    }

    function _onlyKeeper() internal view {
        if (msg.sender != keeper) revert HV_Unauthorized();
    }

    function _onlyOwner() internal view {
        if (msg.sender != owner()) revert HV_Unauthorized();
    }

    function _onlyPauser() internal view {
        if (msg.sender != vaultPauser) revert HTV_Unauthorized();
    }

    /************************************************
     *  SETTERS
     ***********************************************/

    /**
     * @notice Sets the new keeper
     * @param newKeeper is the address of the new keeper
     */
    function setNewKeeper(address newKeeper) external {
        _onlyOwner();

        if (newKeeper == address(0)) revert HV_BadAddress();

        keeper = newKeeper;
    }

    /**
     * @notice Sets the new fee recipient
     * @param newFeeRecipient is the address of the new fee recipient
     */
    function setFeeRecipient(address newFeeRecipient) external {
        _onlyOwner();

        if (newFeeRecipient == address(0) || newFeeRecipient == feeRecipient) revert HV_BadAddress();

        feeRecipient = newFeeRecipient;
    }

    /**
     * @notice Sets the management fee for the vault
     * @param newManagementFee is the management fee (6 decimals). ex: 2 * 10 ** 6 = 2%
     */
    function setManagementFee(uint256 newManagementFee) external {
        _onlyOwner();

        if (newManagementFee > 100 * Vault.FEE_MULTIPLIER) revert HV_BadFee();

        emit ManagementFeeSet(managementFee, newManagementFee);

        managementFee = newManagementFee;
    }

    /**
     * @notice Sets the performance fee for the vault
     * @param newPerformanceFee is the performance fee (6 decimals). ex: 20 * 10 ** 6 = 20%
     */
    function setPerformanceFee(uint256 newPerformanceFee) external {
        _onlyOwner();

        if (newPerformanceFee > 100 * Vault.FEE_MULTIPLIER) revert HV_BadFee();

        emit PerformanceFeeSet(performanceFee, newPerformanceFee);

        performanceFee = newPerformanceFee;
    }

    /**
     * @notice Sets a new cap for deposits
     * @param newCap is the new cap for deposits
     */
    // function setCap(uint256 newCap) external {
    //     _onlyOwner();

    //     if (newCap == 0) revert HV_BadCap();

    //     ShareMath.assertUint104(newCap);

    //     emit CapSet(vaultParams.cap, newCap);

    //     vaultParams.cap = uint104(newCap);
    // }

    /**
     * @notice Sets the new Vault Pauser contract for this vault
     * @param newVaultPauser is the address of the new vaultPauser contract
     */
    function setVaultPauser(address newVaultPauser) external {
        _onlyOwner();

        vaultPauser = newVaultPauser;
    }

    /**
     * @notice Sets the whitelist contract
     * @param newWhitelist is the address of the new whitelist
     */
    function setWhitelist(address newWhitelist) external {
        _onlyOwner();

        whitelist = newWhitelist;
    }

    /************************************************
     *  DEPOSIT & WITHDRAWALS
     ***********************************************/

    function _depositCollaterals(uint256 amount) internal {
        VaultLifecycle.transferCollaterals(amount, collaterals, roundStartingBalances[vaultState.round], address(this));
    }

    function _withdrawCollaterals(uint256 amount) internal {
        VaultLifecycle.transferCollaterals(amount, collaterals, roundStartingBalances[vaultState.round], msg.sender);
    }

    /**
     * @notice gets whitelist status of an account
     * @param account address
     */
    function _validateWhitelisted(address account) internal view {
        if (whitelist != address(0) && !IWhitelist(whitelist).isCustomer(account)) revert HV_NotWhitelisted();
    }

    /**
     * @notice Deposits the `asset` from msg.sender added to `creditor`'s deposit
     * @notice Used for vault -> vault deposits on the user's behalf
     * @param amount is the amount of `asset` to deposit
     * @param creditor is the address that can claim/withdraw deposited amount
     */
    function depositFor(uint256 amount, address creditor) external nonReentrant {
        if (amount == 0) revert HV_BadDepositAmount();
        if (creditor == address(0)) creditor = msg.sender;

        _validateWhitelisted(msg.sender);

        if (creditor != msg.sender) _validateWhitelisted(creditor);

        uint256 currentRound = vaultState.round;
        uint256 totalWithDepositedAmount = vaultState.lockedAmount + amount;

        if (totalWithDepositedAmount > vaultParams.cap) revert HV_ExceedsCap();
        if (totalWithDepositedAmount < vaultParams.minimumSupply) revert HV_InsufficientFunds();

        emit Deposit(creditor, amount, currentRound);

        Vault.DepositReceipt memory depositReceipt = depositReceipts[creditor];

        // If we have an unprocessed pending deposit from the previous rounds, we have to process it.
        uint256 unredeemedShares;
        if (depositReceipt.amount > 0)
            unredeemedShares = depositReceipt.getSharesFromReceipt(
                currentRound,
                roundPricePerShare[depositReceipt.round],
                _relativeNAVInRound(depositReceipt.round, depositReceipt.amount)
            );

        uint256 depositAmount = amount;

        // If we have a pending deposit in the current round, we add on to the pending deposit
        if (currentRound == depositReceipt.round) {
            uint256 newAmount = uint256(depositReceipt.amount).add(amount);
            depositAmount = newAmount;
        }

        ShareMath.assertUint104(depositAmount);

        depositReceipts[creditor] = Vault.DepositReceipt({
            round: uint16(currentRound),
            amount: uint104(depositAmount),
            unredeemedShares: uint128(unredeemedShares)
        });

        uint256 newTotalPending = uint256(vaultState.totalPending).add(amount);
        ShareMath.assertUint128(newTotalPending);

        vaultState.totalPending = uint128(newTotalPending);

        // An approve() by the msg.sender is required beforehand
        _depositCollaterals(amount);
    }

    /**
     * @notice pause a user's vault position
     */
    function pausePosition() external {
        if (vaultPauser == address(0)) revert HTV_BadAddress();

        redeem(0, true);

        uint256 heldByAccount = balanceOf(msg.sender);

        _approve(msg.sender, vaultPauser, heldByAccount);

        IVaultPauser(vaultPauser).pausePosition(msg.sender, heldByAccount);
    }

    /**
     * @notice Withdraws the assets on the vault using the outstanding `DepositReceipt.amount`
     * @param amount is the amount to withdraw
     */
    function withdrawInstantly(uint256 amount) external nonReentrant {
        if (amount == 0) revert HV_BadAmount();

        Vault.DepositReceipt storage depositReceipt = depositReceipts[msg.sender];

        uint256 currentRound = vaultState.round;

        if (depositReceipt.round != currentRound) revert HV_BadRound();

        uint256 receiptAmount = depositReceipt.amount;

        if (receiptAmount < amount) revert HV_BadAmount();

        // Subtraction underflow checks already ensure it is smaller than uint104
        depositReceipt.amount = uint104(receiptAmount.sub(amount));
        vaultState.totalPending = uint128(uint256(vaultState.totalPending).sub(amount));

        emit InstantWithdraw(msg.sender, amount, currentRound);

        _withdrawCollaterals(amount);
    }

    /**
     * @notice Initiates a withdrawal that can be processed once the round completes
     * @param numShares is the number of shares to withdraw
     */
    function initiateWithdraw(uint256 numShares) external {
        _onlyPauser();

        if (numShares == 0) revert HV_BadNumShares();

        ShareMath.assertUint128(numShares);

        // We do a max redeem before initiating a withdrawal
        // But we check if they must first have unredeemed shares
        if (depositReceipts[msg.sender].amount > 0 || depositReceipts[msg.sender].unredeemedShares > 0) {
            redeem(0, true);
        }

        // This caches the `round` variable used in shareBalances
        uint256 currentRound = vaultState.round;
        Vault.Withdrawal storage withdrawal = withdrawals[msg.sender];

        bool withdrawalIsSameRound = withdrawal.round == currentRound;

        emit InitiateWithdraw(msg.sender, numShares, currentRound);

        uint256 existingShares = uint256(withdrawal.shares);

        uint256 withdrawalShares;
        if (withdrawalIsSameRound) {
            withdrawalShares = existingShares.add(numShares);
        } else {
            if (existingShares > 0) revert HV_ExistingWithdraw();

            withdrawalShares = numShares;
            withdrawals[msg.sender].round = uint16(currentRound);
        }

        ShareMath.assertUint128(withdrawalShares);
        withdrawals[msg.sender].shares = uint128(withdrawalShares);

        unchecked {
            vaultState.queuedWithdrawShares += uint128(numShares);
        }

        _transfer(msg.sender, address(this), numShares);
    }

    /**
     * @notice Completes a scheduled withdrawal from a past round. Uses finalized pps for the round
     */
    function completeWithdraw() external {
        _onlyPauser();

        Vault.Withdrawal storage withdrawal = withdrawals[msg.sender];

        uint256 withdrawalShares = withdrawal.shares;
        uint256 withdrawalRound = withdrawal.round;

        // This checks if there is a withdrawal
        if (withdrawalShares == 0) revert HV_Uninitialized();

        if (withdrawalRound >= vaultState.round) revert HV_RoundNotClosed();

        // We leave the round number as non-zero to save on gas for subsequent writes
        withdrawals[msg.sender].shares = 0;

        // must store this value before burning
        uint256 currentSupply = totalSupply();

        _burn(address(this), withdrawalShares);

        // TODO
        // emit Withdraw(msg.sender, withdrawAmount, withdrawalShares);

        VaultLifecycle.withdrawCollateralsWithShares(withdrawalShares, currentSupply, collaterals);
    }

    /**
     * @notice Redeems shares that are owed to the account
     * @param numShares is the number of shares to redeem, could be 0 when isMax=true
     * @param isMax is flag for when callers do a max redemption
     */
    function redeem(uint256 numShares, bool isMax) public nonReentrant {
        if (!isMax && numShares == 0) revert HV_BadNumShares();

        Vault.DepositReceipt memory depositReceipt = depositReceipts[msg.sender];

        // This handles the null case when depositReceipt.round = 0
        // Because we start with round = 1 at `initialize`
        uint256 currentRound = vaultState.round;

        uint256 unredeemedShares = depositReceipt.getSharesFromReceipt(
            currentRound,
            roundPricePerShare[depositReceipt.round],
            _relativeNAVInRound(depositReceipt.round, depositReceipt.amount)
        );

        numShares = isMax ? unredeemedShares : numShares;

        if (numShares == 0) return;

        if (numShares > unredeemedShares) revert HV_ExceedsAvailable();

        // If we have a depositReceipt on the same round, BUT we have some unredeemed shares
        // we debit from the unredeemedShares, but leave the amount field intact
        // If the round has past, with no new deposits, we just zero it out for new deposits.
        if (depositReceipt.round < currentRound) depositReceipts[msg.sender].amount = 0;

        ShareMath.assertUint128(numShares);
        depositReceipts[msg.sender].unredeemedShares = uint128(unredeemedShares.sub(numShares));

        emit Redeem(msg.sender, numShares, depositReceipt.round);

        _transfer(address(this), msg.sender, numShares);
    }

    /************************************************
     *  VAULT OPERATIONS
     ***********************************************/

    /**
     * @notice Helper function that helps to save gas for writing values into the roundPricePerShare map.
     *         Writing `1` into the map makes subsequent writes warm, reducing the gas from 20k to 5k.
     *         Having 1 initialized beforehand will not be an issue as long as we round down share calculations to 0.
     * @param numRounds is the number of rounds to initialize in the map
     */
    function initRounds(uint256 numRounds) external {
        uint256 i;
        uint256 _round = vaultState.round;

        uint256[] memory placeholderBalances = new uint256[](collaterals.length);
        for (i; i < placeholderBalances.length; ) {
            placeholderBalances[i] = Vault.PLACEHOLDER_UINT;

            unchecked {
                ++i;
            }
        }

        for (i = 0; i < numRounds; ) {
            uint256 index = _round;

            unchecked {
                index += i;
            }

            if (roundPricePerShare[index] > 0) revert HV_BadPPS();
            if (roundExpiry[index] > 0) revert HV_BadExpiry();
            if (roundStartingBalances[index].length > 0) revert HV_BadSB();

            roundPricePerShare[index] = Vault.PLACEHOLDER_UINT;
            roundExpiry[index] = Vault.PLACEHOLDER_UINT;
            roundStartingBalances[index] = placeholderBalances;

            ++i;
        }
    }

    /**
     * @notice Helper function that performs most administrative tasks
     * such as minting new shares, getting vault fees, etc.
     */
    function _closeRound() internal {
        uint256 mintShares;
        uint256[] memory vaultFees;
        {
            uint256 currentRound = vaultState.round;

            VaultLifecycle.CloseParams memory params;
            params.currentShareSupply = totalSupply();
            params.queuedWithdrawShares = vaultState.queuedWithdrawShares;
            params.managementFee = managementFee;
            params.performanceFee = performanceFee;
            params.feeRecipient = feeRecipient;
            params.oracleAddr = oracle;
            params.collaterals = collaterals;
            params.roundStartingBalances = roundStartingBalances[currentRound];
            params.expiry = roundExpiry[currentRound];

            uint256[] memory collateralBalances;
            uint256 newPricePerShare;
            (collateralBalances, newPricePerShare, mintShares, vaultFees) = VaultLifecycle.closeRound(
                vaultState,
                params
            );

            // Finalize the pricePerShare at the end of the round
            roundPricePerShare[currentRound] = newPricePerShare;

            // setting the balances at the start of the new round
            roundStartingBalances[currentRound + 1] = collateralBalances;

            vaultState.totalPending = 0;
            vaultState.round = uint16(currentRound + 1);
        }

        _mint(address(this), mintShares);

        // TODO
        // address recipient = feeRecipient;
        // emit CollectVaultFees(vaultFees, currentRound, recipient);
    }

    /************************************************
     *  GETTERS
     ***********************************************/

    /**
     * @notice Getter for returning the account's share balance split between account and vault holdings
     * @param account is the account to lookup share balance for
     * @return heldByAccount is the shares held by account
     * @return heldByVault is the shares held on the vault (unredeemedShares)
     */
    function shareBalances(address account) public view returns (uint256 heldByAccount, uint256 heldByVault) {
        Vault.DepositReceipt memory depositReceipt = depositReceipts[account];

        if (depositReceipt.round < Vault.PLACEHOLDER_UINT) return (balanceOf(account), 0);

        heldByVault = depositReceipt.getSharesFromReceipt(
            vaultState.round,
            roundPricePerShare[depositReceipt.round],
            _relativeNAVInRound(depositReceipt.round, depositReceipt.amount)
        );

        heldByAccount = balanceOf(account);
    }

    /**
     * @notice Returns the token decimals
     */
    function decimals() public pure override returns (uint8) {
        return uint8(Vault.DECIMALS);
    }

    function currentOptions() external view returns (uint256[] memory) {
        return optionState.currentOptions;
    }

    function nextOptions() external view returns (uint256[] memory) {
        return optionState.nextOptions;
    }

    function getCollaterals() external view returns (Vault.Collateral[] memory) {
        return collaterals;
    }

    function _relativeNAVInRound(uint256 round, uint256 amount) private view returns (uint256 value) {
        value = VaultLifecycle.calculateRelativeNAV(
            oracle,
            collaterals,
            roundStartingBalances[round],
            amount,
            roundExpiry[round]
        );
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.4;

abstract contract HashnoteOptionsVaultStorageV1 {
    // Auction duration
    uint256 public auctionDuration;
    // Auction id of current option
    uint256 public optionAuctionId;
    // Percentage of lockedAmount used to determine how many structures to mint
    uint256 public leverageRatio;
}

// We are following Compound's method of upgrading new contract implementations
// When we need to add new storage variables, we create a new version of HashnoteOptionsVaultStorage
// e.g. HashnoteOptionsVaultStorage<versionNumber>, so finally it would look like
// contract HashnoteOptionsVaultStorage is HashnoteOptionsVaultStorageV1, HashnoteOptionsVaultStorageV2
abstract contract HashnoteOptionsVaultStorage is HashnoteOptionsVaultStorageV1 {

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.4;

interface IVaultPauser {
    /// @notice pause vault position of an account with max amount
    /// @param _account the address of user
    /// @param _amount amount of shares
    function pausePosition(address _account, uint256 _amount) external;

    /// @notice processes all pending withdrawals
    /// @param _vault the address of vault
    function processVaultWithdraw(address _vault) external;

    /// @notice user withdraws collateral
    /// @param _vault the address of vault
    /// @param _destination the address of the recipient
    function withdrawCollaterals(address _vault, address _destination) external;
}

// SPDX-License-Identifier: MIT

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
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT

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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

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
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

import { ISanctionsList } from "../interfaces/IWhitelist.sol";
import "../utils/Error.sol";

contract HashnoteWhitelistManager is Ownable {
    bytes32 public constant CUSTOMER_ROLE = keccak256("CUSTOMER_ROLE");
    bytes32 public constant LP_ROLE = keccak256("LP_ROLE");
    bytes32 public constant VAULT_ROLE = keccak256("VAULT_ROLE");
    bytes32 public constant OTC_ROLE = keccak256("OTC_ROLE");

    address public sanctionsOracle;

    mapping(bytes32 => mapping(address => bool)) public permissions;

    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    constructor() {}

    /**
     * @notice Sets the new oracle address
     * @param _sanctionsOracle is the address of the new oracle
     */
    function setSanctionsOracle(address _sanctionsOracle) external {
        _checkOwner();

        if (_sanctionsOracle == address(0)) revert WLM_BadAddress();

        sanctionsOracle = _sanctionsOracle;
    }

    /**
     * @notice Checks if customer has been whitelisted
     * @param _address the address of the account
     * @return value returning if allowed to transact
     */
    function isCustomer(address _address) external view returns (bool) {
        return hasRoleAndNotSanctioned(CUSTOMER_ROLE, _address);
    }

    /**
     * @notice Checks if LP has been whitelisted
     * @param _address the address of the LP Wallet
     * @return value returning if allowed to transact
     */
    function isLP(address _address) external view returns (bool) {
        return hasRoleAndNotSanctioned(LP_ROLE, _address);
    }

    /**
     * @notice Checks if Vault has been whitelisted
     * @param _address the address of the Vault
     * @return value returning if allowed to transact
     */
    function isVault(address _address) external view returns (bool) {
        return hasRole(VAULT_ROLE, _address);
    }

    /*
     * @notice Checks if OTC has been whitelisted
     * @param _address the address of the OTC
     * @return value returning if allowed to transact
     */
    function isOTC(address _address) external view returns (bool) {
        return hasRoleAndNotSanctioned(OTC_ROLE, _address);
    }

    /**
     * @notice Checks if address has been whitelisted
     * @param _address the address
     * @return value returning if allowed to transact
     */
    function engineAccess(address _address) external view returns (bool) {
        return
            (hasRole(VAULT_ROLE, _address) || hasRole(LP_ROLE, _address) || hasRole(CUSTOMER_ROLE, _address)) &&
            !sanctioned(_address);
    }

    function grantRole(bytes32 role, address _address) external {
        _checkOwner();

        permissions[role][_address] = true;

        emit RoleGranted(role, _address, _msgSender());
    }

    function revokeRole(bytes32 role, address _address) external {
        _checkOwner();

        permissions[role][_address] = false;

        emit RoleRevoked(role, _address, _msgSender());
    }

    /**
     * @notice Checks if an address has a specific role and is not sanctioned
     * @param role the the specific role
     * @param _address the address
     * @return value returning if allowed to transact
     */
    function hasRoleAndNotSanctioned(bytes32 role, address _address) public view returns (bool) {
        return hasRole(role, _address) && !sanctioned(_address);
    }

    /**
     * @notice Checks if an address has a specific role
     * @param role the the specific role
     * @param _address the address
     * @return value returning if allowed to transact
     */
    function hasRole(bytes32 role, address _address) public view returns (bool) {
        if (role == bytes32(0)) revert WLM_BadRole();
        if (_address == address(0)) revert WLM_BadAddress();
        return permissions[role][_address];
    }

    /**
     * @notice Checks if an address is sanctioned
     * @param _address the address
     * @return value returning if allowed to transact
     */
    function sanctioned(address _address) public view returns (bool) {
        if (_address == address(0)) revert WLM_BadAddress();

        return sanctionsOracle != address(0) ? ISanctionsList(sanctionsOracle).isSanctioned(_address) : false;
    }

    function _checkOwner() internal view {
        if (owner() != _msgSender()) revert WLM_Unauthorized();
    }
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.4;
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { FixedPointMathLib } from "solmate/src/utils/FixedPointMathLib.sol";

import { IVaultPauser } from "../interfaces/IVaultPauser.sol";
import { IHashnoteOptionsVault } from "../interfaces/IHashnoteOptionsVault.sol";
import { IWhitelist } from "../interfaces/IWhitelist.sol";

import { Vault } from "../libraries/Vault.sol";
import { ShareMath } from "../libraries/ShareMath.sol";
import "../utils/Error.sol";

import "hardhat/console.sol";

contract HashnoteVaultPauser is Ownable, IVaultPauser {
    using FixedPointMathLib for uint256;
    using SafeERC20 for IERC20;

    /************************************************
     *  NON UPGRADEABLE STORAGE
     ***********************************************/

    /// @notice Stores all the vault's paused positions
    struct PauseReceipt {
        uint32 round;
        uint128 shares;
    }

    // vault => account => pause receipt
    mapping(address => mapping(address => PauseReceipt)) public pausedPositions;

    // vault => round => total withdrawn shares
    mapping(address => mapping(uint256 => uint128)) public roundTotalShares;

    // vault => round => array of collateral balances
    mapping(address => mapping(uint256 => uint256[])) public roundBalances;

    IWhitelist public whitelist;

    /************************************************
     *  EVENTS
     ***********************************************/

    event Pause(address indexed account, address indexed vaultAddress, uint256 share, uint256 round);

    event Withdraw(address indexed account, address indexed vaultAddress, uint256[] withdrawAmounts);

    event ProcessWithdraws(address indexed vaultAddress, uint256 round, uint256[] withdrawAmounts);

    /************************************************
     *  CONSTRUCTOR & INITIALIZATION
     ***********************************************/

    /**
     * @notice Initializes the contract with immutable variables
     */
    constructor() {}

    /**
     * @dev Throws if called by any account other than the owner.
     */
    function _onlyOwner() internal view {
        if (msg.sender != owner()) revert HVP_Unauthorized();
    }

    /************************************************
     *  GETTERS
     ***********************************************/

    function getPausePosition(address _vault, address _userAddress) external view returns (PauseReceipt memory) {
        return pausedPositions[_vault][_userAddress];
    }

    /************************************************
     *  SETTERS
     ***********************************************/

    /**
     * @notice Sets the whitelist contract
     * @param _whitelist is the address of the new whitelist
     */
    function setWhitelist(address _whitelist) external {
        _onlyOwner();

        whitelist = IWhitelist(_whitelist);
    }

    /************************************************
     *  VAULT OPERATIONS
     ***********************************************/

    /**
     * @notice pause position from vault by redeem all the shares from vault to Pauser
     * @param _account user's address
     * @param _amount the amount of shares
     */
    function pausePosition(address _account, uint256 _amount) external override {
        address _vault = msg.sender;
        IHashnoteOptionsVault vault = IHashnoteOptionsVault(_vault);

        // check if vault is registered
        if (!whitelist.isVault(_vault)) revert HVP_VaultNotFound();

        PauseReceipt storage pausedPosition = pausedPositions[_vault][_account];

        // check if position is paused
        if (pausedPosition.shares > 0 || pausedPosition.round > 0) revert HVP_PositionPaused();

        uint32 round = vault.vaultState().round;

        if (_amount >= type(uint128).max) revert HVP_Overflow();

        pausedPositions[_vault][_account] = PauseReceipt({ round: round, shares: uint128(_amount) });

        roundTotalShares[_vault][round] += uint128(_amount);

        emit Pause(_account, _vault, _amount, round);

        // transfer from user to pauser
        IERC20(_vault).safeTransferFrom(_account, address(this), _amount);

        vault.initiateWithdraw(_amount);
    }

    /**
     * @notice customer withdraws collateral
     * @param _vault vault's address
     * @param _destination address
     */
    function withdrawCollaterals(address _vault, address _destination) external override {
        // check if vault is registered
        if (!whitelist.isVault(_vault)) revert HVP_VaultNotFound();

        if (_destination == address(0)) _destination = msg.sender;

        IHashnoteOptionsVault vault = IHashnoteOptionsVault(_vault);

        // get current round
        uint256 round = vault.vaultState().round;

        PauseReceipt memory pauseReceipt = pausedPositions[_vault][msg.sender];
        uint256 pauseReceiptRound = pauseReceipt.round;

        // check if round is closed before resuming position
        if (pauseReceiptRound >= round) revert HVP_RoundOpen();

        // delete position once transfer (revert to zero)
        delete pausedPositions[_vault][msg.sender];

        _withdrawCollaterals(vault, _destination, pauseReceipt);
    }

    /**
     * @notice process withdrawals by completing in a batch
     * @param _vault vault's address to be processed
     */
    function processVaultWithdraw(address _vault) external override {
        // check if vault is registered
        if (!whitelist.isVault(_vault)) revert HVP_VaultNotFound();

        IHashnoteOptionsVault vault = IHashnoteOptionsVault(_vault);
        // we can only process withdrawal after closing the previous round
        // hence round should be - 1
        uint256 round = vault.vaultState().round - 1;

        Vault.Collateral[] memory collaterals = vault.getCollaterals();

        uint256[] memory beforeBalances = _getCollateralBalances(collaterals);

        vault.completeWithdraw();

        uint256[] memory afterBalances = _getCollateralBalances(collaterals);

        uint256[] memory balances = new uint256[](collaterals.length);

        for (uint256 i; i < collaterals.length; ) {
            balances[i] = afterBalances[i] - beforeBalances[i];

            unchecked {
                ++i;
            }
        }

        roundBalances[address(vault)][round] = balances;

        emit ProcessWithdraws(_vault, round, balances);
    }

    /**
     * @notice Recovery function that returns an ERC20 token to the recipient
     * @param token is the ERC20 token to recover from the vault
     * @param recipient is the recipient of the recovered tokens
     */
    function recoverTokens(address token, address recipient) external {
        _onlyOwner();

        if (recipient == address(0) || recipient == address(this)) revert HVP_BadAddress();

        IERC20(token).safeTransfer(recipient, IERC20(token).balanceOf(address(this)));
    }

    function _withdrawCollaterals(
        IHashnoteOptionsVault vault,
        address _destination,
        PauseReceipt memory pauseReceipt
    ) private {
        uint256 round = pauseReceipt.round;
        uint256[] memory balances = roundBalances[address(vault)][round];
        uint256 totalShares = roundTotalShares[address(vault)][round];

        Vault.Collateral[] memory collaterals = vault.getCollaterals();

        uint256[] memory amounts = new uint256[](collaterals.length);

        for (uint256 i; i < collaterals.length; ) {
            amounts[i] = balances[i].mulDivDown(pauseReceipt.shares, totalShares);

            if (amounts[i] > 0) IERC20(collaterals[i].addr).safeTransfer(_destination, amounts[i]);

            unchecked {
                ++i;
            }
        }

        emit Withdraw(msg.sender, address(vault), amounts);
    }

    function _getCollateralBalances(
        Vault.Collateral[] memory collaterals
    ) private view returns (uint256[] memory balances) {
        balances = new uint256[](collaterals.length);

        for (uint256 i; i < collaterals.length; ) {
            balances[i] = IERC20(collaterals[i].addr).balanceOf(address(this));

            unchecked {
                ++i;
            }
        }
    }

    fallback() external payable {}

    receive() external payable {}
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.4;

import { Vault } from "../libraries/Vault.sol";

interface IHashnoteOptionsVault {
    function currentOptionId() external view returns (address);

    function nextOptionId() external view returns (address);

    function vaultParams() external view returns (Vault.VaultParams memory);

    function vaultState() external view returns (Vault.VaultState memory);

    function optionState() external view returns (Vault.OptionState memory);

    function optionAuctionId() external view returns (uint256);

    function pricePerShare() external view returns (uint256);

    function roundPricePerShare(uint256) external view returns (uint256);

    function roundStartingBalances(uint256) external view returns (uint256[] memory);

    function depositFor(uint256 amount, address creditor) external;

    function initiateWithdraw(uint256 numShares) external;

    function completeWithdraw() external;

    function maxRedeem() external;

    function depositYieldTokenFor(uint256 amount, address creditor) external;

    function symbol() external view returns (string calldata);

    function novate(
        address recipient,
        uint256 amount,
        uint256[] calldata options,
        uint256[] calldata counterparty
    ) external;

    function instruments() external view returns (Vault.Instrument[] memory);

    function getCollaterals() external view returns (Vault.Collateral[] memory);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../../lib/grappa/src/interfaces/IOracle.sol";

import "hardhat/console.sol";

contract MockOracle is IOracle {
    struct MockPrice {
        uint128 price;
        bool isFinalized;
    }

    mapping(address => uint256) public spotPrice;
    mapping(address => mapping(address => mapping(uint256 => MockPrice))) public expiryPrice;

    uint256 private disputePeriod;

    function maxDisputePeriod() external view override returns (uint256) {
        return disputePeriod;
    }

    function getSpotPrice(address _underlying, address /*_strike*/) external view override returns (uint256) {
        return spotPrice[_underlying];
    }

    function getPriceAtExpiry(
        address base,
        address quote,
        uint256 expiry
    ) external view override returns (uint256, bool) {
        MockPrice memory p = expiryPrice[base][quote][expiry];
        return (p.price, p.isFinalized);
    }

    function setViewDisputePeriod(uint256 _period) external {
        disputePeriod = _period;
    }

    function setSpotPrice(address _asset, uint256 _mockedSpotPrice) external {
        spotPrice[_asset] = _mockedSpotPrice;
    }

    function setExpiryPrice(address base, address quote, uint256 expiry, uint256 _mockedExpiryPrice) external {
        // console.log("setExpiryPrice base", base);
        // console.log("setExpiryPrice quote", quote);
        // console.log("setExpiryPrice expiry", expiry);
        // console.log("setExpiryPrice price", _mockedExpiryPrice);
        expiryPrice[base][quote][expiry] = MockPrice(uint128(_mockedExpiryPrice), true);
    }

    function setExpiryPriceWithFinality(
        address base,
        address quote,
        uint256 expiry,
        uint256 _mockedExpiryPrice,
        bool _isFinalized
    ) external {
        expiryPrice[base][quote][expiry] = MockPrice(uint128(_mockedExpiryPrice), _isFinalized);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOracle {
    /**
     * @notice  get spot price of _base, denominated in _quote.
     * @param _base base asset. for ETH/USD price, ETH is the base asset
     * @param _quote quote asset. for ETH/USD price, USD is the quote asset
     * @return price with 6 decimals
     */
    function getSpotPrice(address _base, address _quote) external view returns (uint256);

    /**
     * @dev get expiry price of underlying, denominated in strike asset.
     * @param _base base asset. for ETH/USD price, ETH is the base asset
     * @param _quote quote asset. for ETH/USD price, USD is the quote asset
     * @param _expiry expiry timestamp
     *
     * @return price with 6 decimals
     */
    function getPriceAtExpiry(address _base, address _quote, uint256 _expiry)
        external
        view
        returns (uint256 price, bool isFinalized);

    /**
     * @dev return the maximum dispute period for the oracle
     * @dev this will only be checked during oracle registration, as a soft constraint on integrating oracles.
     */
    function maxDisputePeriod() external view returns (uint256 disputePeriod);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

// imported contracts and libraries
import {UUPSUpgradeable} from "lib/grappa/lib/openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "lib/grappa/lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "lib/grappa/lib/openzeppelin-contracts-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol";

// inheriting contracts
import {BaseEngine} from "../BaseEngine.sol";
import {SafeCast} from "lib/grappa/lib/openzeppelin-contracts/contracts/utils/math/SafeCast.sol";

// interfaces
import {IOracle} from "../../../interfaces/IOracle.sol";
import {IMarginEngine} from "../../../interfaces/IMarginEngine.sol";
import {IWhitelist} from "../../../interfaces/IWhitelist.sol";

// librarise
import {TokenIdUtil} from "../../../libraries/TokenIdUtil.sol";
import {ProductIdUtil} from "../../../libraries/ProductIdUtil.sol";
import {BalanceUtil} from "../../../libraries/BalanceUtil.sol";
import {ArrayUtil} from "../../../libraries/ArrayUtil.sol";

// Cross margin libraries
import {AccountUtil} from "./AccountUtil.sol";
import {CrossMarginMath} from "./CrossMarginMath.sol";
import {CrossMarginLib} from "./CrossMarginLib.sol";

// Cross margin types
import "./types.sol";

// global constants and types
import "../../../config/types.sol";
import "../../../config/enums.sol";
import "../../../config/constants.sol";
import "../../../config/errors.sol";

/**
 * @title   CrossMarginEngine
 * @author  @dsshap, @antoncoding
 * @notice  Fully collateralized margin engine
 *             Users can deposit collateral into Cross Margin and mint optionTokens (debt) out of it.
 *             Interacts with OptionToken to mint / burn
 *             Interacts with grappa to fetch registered asset info
 */
contract CrossMarginEngine is BaseEngine, IMarginEngine, OwnableUpgradeable, ReentrancyGuardUpgradeable, UUPSUpgradeable {
    using AccountUtil for Position[];
    using AccountUtil for PositionOptim[];
    using BalanceUtil for Balance[];
    using CrossMarginLib for CrossMarginAccount;
    using ProductIdUtil for uint40;
    using SafeCast for uint256;
    using SafeCast for int256;
    using TokenIdUtil for uint256;

    /*///////////////////////////////////////////////////////////////
                         State Variables V1
    //////////////////////////////////////////////////////////////*/

    ///@dev subAccount => CrossMarginAccount structure.
    ///     subAccount can be an address similar to the primary account, but has the last 8 bits different.
    ///     this give every account access to 256 sub-accounts
    mapping(address => CrossMarginAccount) internal accounts;

    ///@dev contract that verifys permissions
    ///     if not set allows anyone to transact
    ///     checks msg.sender on execute & batchExecute
    ///     checks receipient on payCashValue
    IWhitelist public whitelist;

    /*///////////////////////////////////////////////////////////////
                Constructor for implementation Contract
    //////////////////////////////////////////////////////////////*/

    // solhint-disable-next-line no-empty-blocks
    constructor(address _grappa, address _optionToken) BaseEngine(_grappa, _optionToken) initializer {}

    /*///////////////////////////////////////////////////////////////
                            Initializer
    //////////////////////////////////////////////////////////////*/

    function initialize() external initializer {
        __Ownable_init();
    }

    /*///////////////////////////////////////////////////////////////
                    Override Upgrade Permission
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Upgradable by the owner.
     *
     */
    function _authorizeUpgrade(address /*newImplementation*/ ) internal view override {
        _checkOwner();
    }

    /*///////////////////////////////////////////////////////////////
                        External Functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets the whitelist contract
     * @param _whitelist is the address of the new whitelist
     */
    function setWhitelist(address _whitelist) external {
        _checkOwner();

        whitelist = IWhitelist(_whitelist);
    }

    /**
     * @notice batch execute on multiple subAccounts
     * @dev    check margin after all subAccounts are updated
     *         because we support actions like `TransferCollateral` that moves collateral between subAccounts
     */
    function batchExecute(BatchExecute[] calldata batchActions) external nonReentrant {
        _checkPermissioned(msg.sender);

        uint256 i;
        for (i; i < batchActions.length;) {
            address subAccount = batchActions[i].subAccount;
            ActionArgs[] calldata actions = batchActions[i].actions;

            _execute(subAccount, actions);

            // increase i without checking overflow
            unchecked {
                ++i;
            }
        }

        for (i = 0; i < batchActions.length;) {
            if (!_isAccountAboveWater(batchActions[i].subAccount)) revert BM_AccountUnderwater();

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice execute multiple actions on one subAccounts
     * @dev    check margin all actions are applied
     */
    function execute(address _subAccount, ActionArgs[] calldata actions) external override nonReentrant {
        _checkPermissioned(msg.sender);

        _execute(_subAccount, actions);

        if (!_isAccountAboveWater(_subAccount)) revert BM_AccountUnderwater();
    }

    /**
     * @notice payout to user on settlement.
     * @dev this can only triggered by Grappa, would only be called on settlement.
     * @param _asset asset to transfer
     * @param _recipient receiver
     * @param _amount amount
     */
    function payCashValue(address _asset, address _recipient, uint256 _amount) public override (BaseEngine, IMarginEngine) {
        _checkPermissioned(_recipient);

        BaseEngine.payCashValue(_asset, _recipient, _amount);
    }

    /**
     * @notice get minimum collateral needed for a margin account
     * @param _subAccount account id.
     * @return balances array of collaterals and amount (signed)
     */
    function getMinCollateral(address _subAccount) external view returns (Balance[] memory) {
        CrossMarginAccount memory account = accounts[_subAccount];
        return _getMinCollateral(account);
    }

    /**
     * @notice  move an account to someone else
     * @dev     expected to be call by account owner
     * @param _subAccount the id of subaccount to trnasfer
     * @param _newSubAccount the id of receiving account
     */
    function transferAccount(address _subAccount, address _newSubAccount) external {
        if (!_isPrimaryAccountFor(msg.sender, _subAccount)) revert NoAccess();

        if (!accounts[_newSubAccount].isEmpty()) revert CM_AccountIsNotEmpty();
        accounts[_newSubAccount] = accounts[_subAccount];

        delete accounts[_subAccount];
    }

    /**
     * @dev view function to get all shorts, longs and collaterals
     */
    function marginAccounts(address _subAccount)
        external
        view
        returns (Position[] memory shorts, Position[] memory longs, Balance[] memory collaterals)
    {
        CrossMarginAccount memory account = accounts[_subAccount];

        return (account.shorts.getPositions(), account.longs.getPositions(), account.collaterals);
    }

    /**
     * @notice get minimum collateral needed for a margin account
     * @param shorts positions.
     * @param longs positions.
     * @return balances array of collaterals and amount
     */
    function previewMinCollateral(Position[] memory shorts, Position[] memory longs) external view returns (Balance[] memory) {
        CrossMarginAccount memory account;

        account.shorts = shorts.getPositionOptims();
        account.longs = longs.getPositionOptims();

        return _getMinCollateral(account);
    }

    /**
     * ========================================================= **
     *             Override Internal Functions For Each Action
     * ========================================================= *
     */

    /**
     * @notice  settle the margin account at expiry
     * @dev     override this function from BaseEngine
     *             because we get the payout while updating the storage during settlement
     * @dev     this update the account storage
     */
    function _settle(address _subAccount) internal override {
        // update the account in state
        (, Balance[] memory shortPayouts) = accounts[_subAccount].settleAtExpiry(grappa);
        emit AccountSettled(_subAccount, shortPayouts);
    }

    /**
     * ========================================================= **
     *               Override Sate changing functions             *
     * ========================================================= *
     */

    function _addCollateralToAccount(address _subAccount, uint8 collateralId, uint80 amount) internal override {
        accounts[_subAccount].addCollateral(collateralId, amount);
    }

    function _removeCollateralFromAccount(address _subAccount, uint8 collateralId, uint80 amount) internal override {
        accounts[_subAccount].removeCollateral(collateralId, amount);
    }

    function _increaseShortInAccount(address _subAccount, uint256 tokenId, uint64 amount) internal override {
        accounts[_subAccount].mintOption(tokenId, amount);
    }

    function _decreaseShortInAccount(address _subAccount, uint256 tokenId, uint64 amount) internal override {
        accounts[_subAccount].burnOption(tokenId, amount);
    }

    function _increaseLongInAccount(address _subAccount, uint256 tokenId, uint64 amount) internal override {
        accounts[_subAccount].addOption(tokenId, amount);
    }

    function _decreaseLongInAccount(address _subAccount, uint256 tokenId, uint64 amount) internal override {
        accounts[_subAccount].removeOption(tokenId, amount);
    }

    /**
     * ========================================================= **
     *                 Override view functions for BaseEngine
     * ========================================================= *
     */

    /**
     * @dev because we override _settle(), this function is not used
     */
    // solhint-disable-next-line no-empty-blocks
    function _getAccountPayout(address) internal view override returns (uint8, uint80) {}

    /**
     * @dev return whether if an account is healthy.
     * @param _subAccount subaccount id
     * @return isHealthy true if account is in good condition, false if it's underwater (liquidatable)
     */
    function _isAccountAboveWater(address _subAccount) internal view override returns (bool) {
        CrossMarginAccount memory account = accounts[_subAccount];

        Balance[] memory balances = account.collaterals;

        Balance[] memory minCollateralAmounts = _getMinCollateral(account);

        for (uint256 i; i < minCollateralAmounts.length;) {
            (, Balance memory balance,) = balances.find(minCollateralAmounts[i].collateralId);

            if (balance.amount < minCollateralAmounts[i].amount) return false;

            unchecked {
                ++i;
            }
        }

        return true;
    }

    /**
     * @dev reverts if the account cannot add this token into the margin account.
     * @param tokenId tokenId
     */
    function _verifyLongTokenIdToAdd(uint256 tokenId) internal view override {
        (TokenType optionType, uint40 productId, uint64 expiry,,) = tokenId.parseTokenId();

        // engine only supports calls and puts
        if (optionType != TokenType.CALL && optionType != TokenType.PUT) revert CM_UnsupportedTokenType();

        if (block.timestamp > expiry) revert CM_Option_Expired();

        (, uint8 engineId,,,) = productId.parseProductId();

        // in the future reference a whitelist of engines
        if (engineId != grappa.engineIds(address(this))) revert CM_Not_Authorized_Engine();
    }

    /**
     * ========================================================= **
     *                         Internal Functions
     * ========================================================= *
     */

    /**
     * @notice gets access status of an address
     * @dev if whitelist address is not set, it ignores this
     * @param _address address
     */
    function _checkPermissioned(address _address) internal view {
        if (address(whitelist) != address(0) && !whitelist.engineAccess(_address)) revert NoAccess();
    }

    /**
     * @notice execute multiple actions on one subAccounts
     * @dev    also check access of msg.sender
     */
    function _execute(address _subAccount, ActionArgs[] calldata actions) internal {
        _assertCallerHasAccess(_subAccount);

        // update the account storage and do external calls on the flight
        for (uint256 i; i < actions.length;) {
            if (actions[i].action == ActionType.AddCollateral) {
                _addCollateral(_subAccount, actions[i].data);
            } else if (actions[i].action == ActionType.RemoveCollateral) {
                _removeCollateral(_subAccount, actions[i].data);
            } else if (actions[i].action == ActionType.MintShort) {
                _mintOption(_subAccount, actions[i].data);
            } else if (actions[i].action == ActionType.MintShortIntoAccount) {
                _mintOptionIntoAccount(_subAccount, actions[i].data);
            } else if (actions[i].action == ActionType.BurnShort) {
                _burnOption(_subAccount, actions[i].data);
            } else if (actions[i].action == ActionType.TransferLong) {
                _transferLong(_subAccount, actions[i].data);
            } else if (actions[i].action == ActionType.TransferShort) {
                _transferShort(_subAccount, actions[i].data);
            } else if (actions[i].action == ActionType.TransferCollateral) {
                _transferCollateral(_subAccount, actions[i].data);
            } else if (actions[i].action == ActionType.AddLong) {
                _addOption(_subAccount, actions[i].data);
            } else if (actions[i].action == ActionType.RemoveLong) {
                _removeOption(_subAccount, actions[i].data);
            } else if (actions[i].action == ActionType.SettleAccount) {
                _settle(_subAccount);
            } else {
                revert CM_UnsupportedAction();
            }

            // increase i without checking overflow
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev get minimum collateral requirement for an account
     */
    function _getMinCollateral(CrossMarginAccount memory account) internal view returns (Balance[] memory) {
        return CrossMarginMath.getMinCollateralForPositions(grappa, account.shorts.getPositions(), account.longs.getPositions());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822.sol";
import "../ERC1967/ERC1967Upgrade.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is IERC1822Proxiable, ERC1967Upgrade {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
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
pragma solidity ^0.8.0;

// solhint-disable no-empty-blocks

// imported contracts and libraries
import {SafeERC20} from "lib/grappa/lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "lib/grappa/lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC1155} from "lib/grappa/lib/openzeppelin-contracts/contracts/token/ERC1155/IERC1155.sol";

// interfaces
import {IGrappa} from "../../interfaces/IGrappa.sol";
import {IOptionToken} from "../../interfaces/IOptionToken.sol";
import {IERC20} from "lib/grappa/lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

// librarise
import {TokenIdUtil} from "../../libraries/TokenIdUtil.sol";

// constants and types
import "../../config/types.sol";
import "../../config/enums.sol";
import "../../config/constants.sol";
import "../../config/errors.sol";

/**
 * @title   MarginBase
 * @author  @antoncoding, @dsshap
 * @notice  util functions for MarginEngines
 */
abstract contract BaseEngine {
    using SafeERC20 for IERC20;
    using TokenIdUtil for uint256;

    IGrappa public immutable grappa;
    IOptionToken public immutable optionToken;

    ///@dev maskedAccount => operator => allowedExecutionLeft
    ///     every account can authorize any amount of addresses to modify all sub-accounts he controls.
    ///     allowedExecutionLeft referres to the time left the grantee can update the sub-accounts.
    mapping(uint160 => mapping(address => uint256)) public allowedExecutionLeft;

    /// Events
    event AccountAuthorizationUpdate(uint160 maskId, address account, uint256 updatesAllowed);

    event CollateralAdded(address subAccount, address collateral, uint256 amount);

    event CollateralRemoved(address subAccount, address collateral, uint256 amount);

    event CollateralTransfered(address from, address to, uint8 collateralId, uint256 amount);

    event OptionTokenMinted(address subAccount, uint256 tokenId, uint256 amount);

    event OptionTokenBurned(address subAccount, uint256 tokenId, uint256 amount);

    event OptionTokenAdded(address subAccount, uint256 tokenId, uint64 amount);

    event OptionTokenRemoved(address subAccount, uint256 tokenId, uint64 amount);

    event OptionTokenTransfered(address from, address to, uint256 tokenId, uint64 amount);

    event AccountSettled(address subAccount, Balance[] payouts);

    /**
     * ========================================================= **
     *                         External Functions
     * ========================================================= *
     */

    constructor(address _grappa, address _optionToken) {
        grappa = IGrappa(_grappa);
        optionToken = IOptionToken(_optionToken);
    }

    /**
     * ========================================================= **
     *                         External Functions
     * ========================================================= *
     */

    /**
     * @notice  grant or revoke an account access to all your sub-accounts
     * @dev     expected to be call by account owner
     *          usually user should only give access to helper contracts
     * @param   _account account to update authorization
     * @param   _allowedExecutions how many times the account is authrized to update your accounts.
     *          set to max(uint256) to allow premanent access
     */
    function setAccountAccess(address _account, uint256 _allowedExecutions) external {
        uint160 maskedId = uint160(msg.sender) | 0xFF;
        allowedExecutionLeft[maskedId][_account] = _allowedExecutions;

        emit AccountAuthorizationUpdate(maskedId, _account, _allowedExecutions);
    }

    /**
     * @dev resolve access granted to yourself
     * @param _granter address that granted you access
     */
    function revokeSelfAccess(address _granter) external {
        uint160 maskedId = uint160(_granter) | 0xFF;
        allowedExecutionLeft[maskedId][msg.sender] = 0;

        emit AccountAuthorizationUpdate(maskedId, msg.sender, 0);
    }

    /**
     * @notice payout to user on settlement.
     * @dev this can only triggered by Grappa, would only be called on settlement.
     * @param _asset asset to transfer
     * @param _recipient receiber
     * @param _amount amount
     */
    function payCashValue(address _asset, address _recipient, uint256 _amount) public virtual {
        if (msg.sender != address(grappa)) revert NoAccess();
        if (_recipient != address(this)) IERC20(_asset).safeTransfer(_recipient, _amount);
    }

    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory)
        external
        virtual
        returns (bytes4)
    {
        return this.onERC1155BatchReceived.selector;
    }

    /**
     * ========================================================= **
     *                Internal Functions For Each Action
     * ========================================================= *
     */

    /**
     * @dev pull token from user, increase collateral in account storage
     *         the collateral has to be provided by either caller, or the primary owner of subaccount
     */
    function _addCollateral(address _subAccount, bytes calldata _data) internal virtual {
        // decode parameters
        (address from, uint80 amount, uint8 collateralId) = abi.decode(_data, (address, uint80, uint8));

        if (from != msg.sender && !_isPrimaryAccountFor(from, _subAccount)) revert BM_InvalidFromAddress();

        // update the account in state
        _addCollateralToAccount(_subAccount, collateralId, amount);

        (address collateral,) = grappa.assets(collateralId);

        emit CollateralAdded(_subAccount, collateral, amount);

        IERC20(collateral).safeTransferFrom(from, address(this), amount);
    }

    /**
     * @dev push token to user, decrease collateral in storage
     * @param _data bytes data to decode
     */
    function _removeCollateral(address _subAccount, bytes calldata _data) internal virtual {
        // decode parameters
        (uint80 amount, address recipient, uint8 collateralId) = abi.decode(_data, (uint80, address, uint8));

        // update the account in state
        _removeCollateralFromAccount(_subAccount, collateralId, amount);

        (address collateral,) = grappa.assets(collateralId);

        emit CollateralRemoved(_subAccount, collateral, amount);

        IERC20(collateral).safeTransfer(recipient, amount);
    }

    /**
     * @dev mint option token to user, increase short position (debt) in storage
     * @param _data bytes data to decode
     */
    function _mintOption(address _subAccount, bytes calldata _data) internal virtual {
        // decode parameters
        (uint256 tokenId, address recipient, uint64 amount) = abi.decode(_data, (uint256, address, uint64));

        // update the account in state
        _increaseShortInAccount(_subAccount, tokenId, amount);

        emit OptionTokenMinted(_subAccount, tokenId, amount);

        // mint option token
        optionToken.mint(recipient, tokenId, amount);
    }

    /**
     * @dev mint option token into account, increase short position (debt) and increase long position in storage
     * @param _data bytes data to decode
     */
    function _mintOptionIntoAccount(address _subAccount, bytes calldata _data) internal virtual {
        // decode parameters
        (uint256 tokenId, address recipientSubAccount, uint64 amount) = abi.decode(_data, (uint256, address, uint64));

        // update the account in state
        _increaseShortInAccount(_subAccount, tokenId, amount);

        emit OptionTokenMinted(_subAccount, tokenId, amount);

        _verifyLongTokenIdToAdd(tokenId);

        // update the account in state
        _increaseLongInAccount(recipientSubAccount, tokenId, amount);

        emit OptionTokenAdded(recipientSubAccount, tokenId, amount);

        // mint option token
        optionToken.mint(address(this), tokenId, amount);
    }

    /**
     * @dev burn option token from user, decrease short position (debt) in storage
     *         the option has to be provided by either caller, or the primary owner of subaccount
     * @param _data bytes data to decode
     */
    function _burnOption(address _subAccount, bytes calldata _data) internal virtual {
        // decode parameters
        (uint256 tokenId, address from, uint64 amount) = abi.decode(_data, (uint256, address, uint64));

        // token being burn must come from caller or the primary account for this subAccount
        if (from != msg.sender && !_isPrimaryAccountFor(from, _subAccount)) revert BM_InvalidFromAddress();

        // update the account in state
        _decreaseShortInAccount(_subAccount, tokenId, amount);

        emit OptionTokenBurned(_subAccount, tokenId, amount);

        optionToken.burn(from, tokenId, amount);
    }

    /**
     * @dev Add long token into the account to reduce capital requirement.
     * @param _subAccount subaccount that will be update in place
     */
    function _addOption(address _subAccount, bytes calldata _data) internal virtual {
        // decode parameters
        (uint256 tokenId, uint64 amount, address from) = abi.decode(_data, (uint256, uint64, address));

        // token being burn must come from caller or the primary account for this subAccount
        if (from != msg.sender && !_isPrimaryAccountFor(from, _subAccount)) revert BM_InvalidFromAddress();

        _verifyLongTokenIdToAdd(tokenId);

        // update the state
        _increaseLongInAccount(_subAccount, tokenId, amount);

        emit OptionTokenAdded(_subAccount, tokenId, amount);

        // transfer the option token in
        IERC1155(address(optionToken)).safeTransferFrom(from, address(this), tokenId, amount, "");
    }

    /**
     * @dev Remove long token from the account to increase capital requirement.
     * @param _subAccount subaccount that will be update in place
     */
    function _removeOption(address _subAccount, bytes calldata _data) internal virtual {
        // decode parameters
        (uint256 tokenId, uint64 amount, address to) = abi.decode(_data, (uint256, uint64, address));

        // update the state
        _decreaseLongInAccount(_subAccount, tokenId, amount);

        emit OptionTokenRemoved(_subAccount, tokenId, amount);

        // transfer the option token in
        IERC1155(address(optionToken)).safeTransferFrom(address(this), to, tokenId, amount, "");
    }

    /**
     * @dev Transfers collateral to another account.
     * @param _subAccount subaccount that will be update in place
     */
    function _transferCollateral(address _subAccount, bytes calldata _data) internal virtual {
        // decode parameters
        (uint80 amount, address to, uint8 collateralId) = abi.decode(_data, (uint80, address, uint8));

        // update the account in state
        _removeCollateralFromAccount(_subAccount, collateralId, amount);
        _addCollateralToAccount(to, collateralId, amount);

        emit CollateralTransfered(_subAccount, to, collateralId, amount);
    }

    /**
     * @dev Transfers short tokens to another account.
     * @param _subAccount subaccount that will be update in place
     */
    function _transferShort(address _subAccount, bytes calldata _data) internal virtual {
        // decode parameters
        (uint256 tokenId, address to, uint64 amount) = abi.decode(_data, (uint256, address, uint64));

        _assertCallerHasAccess(to);

        // update the account in state
        _decreaseShortInAccount(_subAccount, tokenId, amount);
        _increaseShortInAccount(to, tokenId, amount);

        emit OptionTokenTransfered(_subAccount, to, tokenId, amount);

        if (!_isAccountAboveWater(to)) revert BM_AccountUnderwater();
    }

    /**
     * @dev Transfers long tokens to another account.
     * @param _subAccount subaccount that will be update in place
     */
    function _transferLong(address _subAccount, bytes calldata _data) internal virtual {
        // decode parameters
        (uint256 tokenId, address to, uint64 amount) = abi.decode(_data, (uint256, address, uint64));

        // update the account in state
        _decreaseLongInAccount(_subAccount, tokenId, amount);
        _increaseLongInAccount(to, tokenId, amount);

        emit OptionTokenTransfered(_subAccount, to, tokenId, amount);
    }

    /**
     * @notice  settle the margin account at expiry
     * @dev     this update the account storage
     */
    function _settle(address _subAccount) internal virtual {
        (uint8 collateralId, uint80 payout) = _getAccountPayout(_subAccount);

        // update the account in state
        _settleAccount(_subAccount, payout);

        Balance[] memory balances = new Balance[](1);
        balances[0] = Balance(collateralId, payout);

        emit AccountSettled(_subAccount, balances);
    }

    /**
     * ========================================================= **
     *                State changing functions to override
     * ========================================================= *
     */
    function _addCollateralToAccount(address _subAccount, uint8 collateralId, uint80 amount) internal virtual {}

    function _removeCollateralFromAccount(address _subAccount, uint8 collateralId, uint80 amount) internal virtual {}

    function _increaseShortInAccount(address _subAccount, uint256 tokenId, uint64 amount) internal virtual {}

    function _decreaseShortInAccount(address _subAccount, uint256 tokenId, uint64 amount) internal virtual {}

    function _increaseLongInAccount(address _subAccount, uint256 tokenId, uint64 amount) internal virtual {}

    function _decreaseLongInAccount(address _subAccount, uint256 tokenId, uint64 amount) internal virtual {}

    function _settleAccount(address _subAccount, uint80 payout) internal virtual {}

    /**
     * ========================================================= **
     *                View functions to override
     * ========================================================= *
     */

    /**
     * @notice [MUST Implement] return amount of collateral that should be reserved to payout long positions
     * @dev     this function will revert when called before expiry
     * @param _subAccount account id
     */
    function _getAccountPayout(address _subAccount) internal view virtual returns (uint8 collateralId, uint80 payout);

    /**
     * @dev [MUST Implement] return whether if an account is healthy.
     * @param _subAccount subaccount id
     * @return isHealthy true if account is in good condition, false if it's underwater (liquidatable)
     */
    function _isAccountAboveWater(address _subAccount) internal view virtual returns (bool);

    /**
     * @dev reverts if the account cannot add this token into the margin account.
     * @param tokenId tokenId
     */
    function _verifyLongTokenIdToAdd(uint256 tokenId) internal view virtual {}

    /**
     * ========================================================= **
     *                Internal view functions
     * ========================================================= *
     */

    /**
     * @notice revert if the msg.sender is not authorized to access an subAccount id
     * @param _subAccount subaccount id
     */
    function _assertCallerHasAccess(address _subAccount) internal {
        if (_isPrimaryAccountFor(msg.sender, _subAccount)) return;

        // the sender is not the direct owner. check if they're authorized
        uint160 maskedAccountId = (uint160(_subAccount) | 0xFF);

        uint256 allowance = allowedExecutionLeft[maskedAccountId][msg.sender];
        if (allowance == 0) revert NoAccess();

        // if allowance is not set to max uint256, reduce the number
        if (allowance != type(uint256).max) allowedExecutionLeft[maskedAccountId][msg.sender] = allowance - 1;
    }

    /**
     * @notice return if {_primary} address is the primary account for {_subAccount}
     */
    function _isPrimaryAccountFor(address _primary, address _subAccount) internal pure returns (bool) {
        return (uint160(_primary) | 0xFF) == (uint160(_subAccount) | 0xFF);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ActionArgs} from "../config/types.sol";

interface IMarginEngine {
    // function getMinCollateral(address _subAccount) external view returns (uint256);

    function execute(address _subAccount, ActionArgs[] calldata actions) external;

    function payCashValue(address _asset, address _recipient, uint256 _amount) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IWhitelist {
    function sanctioned(address _subAccount) external view returns (bool);

    function engineAccess(address _subAccount) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../config/types.sol";

/**
 * Operations on Balance struct
 */
library BalanceUtil {
    function append(Balance[] memory x, Balance memory v) internal pure returns (Balance[] memory y) {
        y = new Balance[](x.length + 1);
        uint256 i;
        for (i; i < x.length;) {
            y[i] = x[i];
            unchecked {
                ++i;
            }
        }
        y[i] = v;
    }

    function find(Balance[] memory x, uint8 v) internal pure returns (bool f, Balance memory b, uint256 i) {
        for (i; i < x.length;) {
            if (x[i].collateralId == v) {
                b = x[i];
                f = true;
                break;
            }
            unchecked {
                ++i;
            }
        }
    }

    function indexOf(Balance[] memory x, uint8 v) internal pure returns (bool f, uint256 i) {
        for (i; i < x.length;) {
            if (x[i].collateralId == v) {
                f = true;
                break;
            }
            unchecked {
                ++i;
            }
        }
    }

    function remove(Balance[] storage x, uint256 y) internal {
        if (y >= x.length) return;
        x[y] = x[x.length - 1];
        x.pop();
    }

    function sum(Balance[] memory x) internal pure returns (uint80 s) {
        for (uint256 i; i < x.length;) {
            s += x[i].amount;
            unchecked {
                ++i;
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {SafeCast} from "lib/grappa/lib/openzeppelin-contracts/contracts/utils/math/SafeCast.sol";

import {IGrappa} from "../../../interfaces/IGrappa.sol";
import {IOracle} from "../../../interfaces/IOracle.sol";

// shard libraries
import {NumberUtil} from "../../../libraries/NumberUtil.sol";
import {ProductIdUtil} from "../../../libraries/ProductIdUtil.sol";
import {TokenIdUtil} from "../../../libraries/TokenIdUtil.sol";
import {BalanceUtil} from "../../../libraries/BalanceUtil.sol";
import {ArrayUtil} from "../../../libraries/ArrayUtil.sol";

// cross margin libraries
import {AccountUtil} from "./AccountUtil.sol";

// Cross margin types
import "./types.sol";

import "../../../config/constants.sol";
import "../../../config/enums.sol";
import "../../../config/errors.sol";

/**
 * @title   CrossMarginMath
 * @notice  this library is in charge of calculating the min collateral for a given cross margin account
 * @dev     deployed as a separate contract to save space
 */
library CrossMarginMath {
    using BalanceUtil for Balance[];
    using AccountUtil for CrossMarginDetail[];
    using AccountUtil for Position[];
    using AccountUtil for PositionOptim[];
    using ArrayUtil for uint256[];
    using ArrayUtil for int256[];
    using SafeCast for int256;
    using SafeCast for uint256;
    using TokenIdUtil for uint256;

    error CM_InvalidPutLengths();

    error CM_InvalidCallLengths();

    error CM_InvalidPutWeight();

    error CM_InvalidCallWeight();

    error CM_InvalidPoints();

    error CM_InvalidLeftPointLength();

    error CM_InvalidRightPointLength();

    /*///////////////////////////////////////////////////////////////
                         Portfolio Margin Requirements
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice get minimum collateral for a given amount of shorts & longs
     * @dev typically used for calculating a portfolios margin requirements
     * @param grappa interface to query grappa contract
     * @param shorts is array of Position structs
     * @param longs is array of Position structs
     * @return amounts is an array of Balance struct representing full collateralization
     */
    function getMinCollateralForPositions(IGrappa grappa, Position[] calldata shorts, Position[] calldata longs)
        external
        view
        returns (Balance[] memory amounts)
    {
        // groups shorts and longs by underlying + strike + collateral + expiry
        CrossMarginDetail[] memory details = _getPositionDetails(grappa, shorts, longs);

        // protfilio has no longs or shorts
        if (details.length == 0) return amounts;

        bool found;
        uint256 index;

        for (uint256 i; i < details.length;) {
            CrossMarginDetail memory detail = details[i];

            // checks that the combination has positions, otherwiser skips
            if (detail.callWeights.length != 0 || detail.putWeights.length != 0) {
                // gets the amount of numeraire and underlying needed
                (uint256 numeraireNeeded, uint256 underlyingNeeded) = getMinCollateral(detail);

                if (numeraireNeeded != 0) {
                    (found, index) = amounts.indexOf(detail.numeraireId);

                    if (found) amounts[index].amount += numeraireNeeded.toUint80();
                    else amounts = amounts.append(Balance(detail.numeraireId, numeraireNeeded.toUint80()));
                }

                if (underlyingNeeded != 0) {
                    (found, index) = amounts.indexOf(detail.underlyingId);

                    if (found) amounts[index].amount += underlyingNeeded.toUint80();
                    else amounts = amounts.append(Balance(detail.underlyingId, underlyingNeeded.toUint80()));
                }
            }

            unchecked {
                ++i;
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                         Cross Margin Calculations
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice get minimum collateral
     * @dev detail is composed of positions with the same underlying + strike + expiry
     * @param _detail margin details
     * @return numeraireNeeded with {numeraire asset's} decimals
     * @return underlyingNeeded with {underlying asset's} decimals
     */
    function getMinCollateral(CrossMarginDetail memory _detail)
        public
        pure
        returns (uint256 numeraireNeeded, uint256 underlyingNeeded)
    {
        _verifyInputs(_detail);

        (uint256[] memory strikes, int256 syntheticUnderlyingWeight, uint256[] memory pois, int256[] memory payouts) =
            _baseSetup(_detail);

        (numeraireNeeded, underlyingNeeded) =
            _calcCollateralNeeds(_detail.putStrikes, _detail.putWeights, _detail.callStrikes.length > 0, pois, payouts);

        // if options collateralizied in underlying, forcing numeraire to be converted to underlying
        // only applied to calls since puts cannot be collateralized in underlying
        if (numeraireNeeded > 0 && _detail.putStrikes.length == 0) {
            numeraireNeeded = 0;

            (, underlyingNeeded) =
                _checkHedgableTailRisk(_detail, pois, payouts, strikes, syntheticUnderlyingWeight, underlyingNeeded, false);
        } else {
            numeraireNeeded = NumberUtil.convertDecimals(numeraireNeeded, UNIT_DECIMALS, _detail.numeraireDecimals);
        }

        underlyingNeeded = NumberUtil.convertDecimals(underlyingNeeded, UNIT_DECIMALS, _detail.underlyingDecimals);
    }

    /**
     * @notice checks inputs for calculating margin, reverts if bad inputs
     * @param _detail margin details
     */
    function _verifyInputs(CrossMarginDetail memory _detail) internal pure {
        if (_detail.callStrikes.length != _detail.callWeights.length) revert CM_InvalidCallLengths();
        if (_detail.putStrikes.length != _detail.putWeights.length) revert CM_InvalidPutLengths();

        uint256 i;
        for (i; i < _detail.putWeights.length;) {
            if (_detail.putWeights[i] == sZERO) revert CM_InvalidPutWeight();

            unchecked {
                ++i;
            }
        }

        for (i = 0; i < _detail.callWeights.length;) {
            if (_detail.callWeights[i] == sZERO) revert CM_InvalidCallWeight();

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice get numeraire and underlying needed to fully collateralize
     * @dev calculates left side and right side of the payout profile
     * @param putStrikes array of put option strikes
     * @param putWeights amount of options at a given strike
     * @param hasCalls has call options
     * @param pois are the strikes we are evaluating
     * @param payouts are the payouts at a given strike
     * @return numeraireNeeded with {numeraire asset's} decimals
     * @return underlyingNeeded with {underlying asset's} decimals
     */
    function _calcCollateralNeeds(
        uint256[] memory putStrikes,
        int256[] memory putWeights,
        bool hasCalls,
        uint256[] memory pois,
        int256[] memory payouts
    ) internal pure returns (uint256 numeraireNeeded, uint256 underlyingNeeded) {
        bool hasPuts = putStrikes.length > 0;

        // if call options exist, get amount of underlying needed (right side of payout profile)
        if (hasCalls) (underlyingNeeded,) = _getUnderlyingNeeded(pois, payouts);

        // if put options exist, get amount of numeraire needed (left side of payout profile)
        if (hasPuts) numeraireNeeded = _getNumeraireNeeded(putStrikes, putWeights);

        // crediting the numeraire if underlying has a positive payout
        numeraireNeeded = _getUnderlyingAdjustedNumeraireNeeded(pois, payouts, numeraireNeeded, underlyingNeeded, hasPuts);
    }

    /**
     * @notice setting up values needed to calculate margin requirements
     * @param _detail margin details
     * @return strikes of shorts and longs
     * @return syntheticUnderlyingWeight sum of put positions (negative)
     * @return pois array of point-of-interests (aka strikes)
     * @return payouts payouts for a given poi position
     */
    function _baseSetup(CrossMarginDetail memory _detail)
        internal
        pure
        returns (uint256[] memory strikes, int256 syntheticUnderlyingWeight, uint256[] memory pois, int256[] memory payouts)
    {
        int256 intrinsicValue;
        int256[] memory weights;

        // using put/call parity to convert puts to calls
        (strikes, weights, syntheticUnderlyingWeight, intrinsicValue) = _convertPutsToCalls(_detail);

        // points-of-interest, array of strikes needed to evaluate collateral requirements
        pois = _createPois(strikes, _detail.putStrikes.length);

        // payouts at each point-of-interest
        payouts = _calcPayouts(pois, strikes, weights, syntheticUnderlyingWeight, _detail.spotPrice, intrinsicValue);
    }

    /**
     * @notice generating points of interest (strikes)
     * @dev adding a point left of left most strike (puts) and a right point of right most strike (call)
     * @param strikes array of shorts and longs
     * @param numOfPuts number of puts
     * @return pois array of point-of-interests (aka strikes)
     */
    function _createPois(uint256[] memory strikes, uint256 numOfPuts) internal pure returns (uint256[] memory pois) {
        (uint256 minStrike, uint256 maxStrike) = strikes.minMax();
        uint256 epsilon = minStrike / 10;

        bool hasPuts = numOfPuts > 0;

        // left of left-most + strikes + right of right-most
        uint256 poiCount = (hasPuts ? 1 : 0) + strikes.length + 1;

        pois = new uint256[](poiCount);

        if (hasPuts) pois[0] = minStrike - epsilon;

        for (uint256 i; i < strikes.length;) {
            uint256 offset = hasPuts ? 1 : 0;

            pois[i + offset] = strikes[i];

            unchecked {
                ++i;
            }
        }

        pois[pois.length - 1] = maxStrike + epsilon;
    }

    /**
     * @notice using put/call parity to convert puts to calls
     * @param _detail margin details
     * @return strikes of call options
     * @return weights amount of options for a given strike
     * @return syntheticUnderlyingWeight sum of put positions (negative)
     * @return intrinsicValue of put payouts
     */
    function _convertPutsToCalls(CrossMarginDetail memory _detail)
        internal
        pure
        returns (uint256[] memory strikes, int256[] memory weights, int256 syntheticUnderlyingWeight, int256 intrinsicValue)
    {
        strikes = _detail.putStrikes.concat(_detail.callStrikes);
        weights = _detail.putWeights.concat(_detail.callWeights);

        // sorting strikes
        uint256[] memory indexes;
        (strikes, indexes) = strikes.argSort();

        // sorting weights based on strike sorted index
        weights = weights.sortByIndexes(indexes);

        syntheticUnderlyingWeight = -_detail.putWeights.sum();

        intrinsicValue = _detail.putStrikes.subEachFrom(_detail.spotPrice).maximum(0).dot(_detail.putWeights) / sUNIT;

        intrinsicValue = -intrinsicValue;
    }

    /**
     * @notice calculate payouts at each point of interest
     * @param pois array of point-of-interests (aka strikes)
     * @param strikes concatentated array of shorts and longs
     * @param weights number of options at each strike
     * @param syntheticUnderlyingWeight sum of put positions (negative)
     * @param spotPrice current price of underlying given a strike asset
     * @param intrinsicValue of put payouts
     * @return payouts payouts for a given poi position
     */
    function _calcPayouts(
        uint256[] memory pois,
        uint256[] memory strikes,
        int256[] memory weights,
        int256 syntheticUnderlyingWeight,
        uint256 spotPrice,
        int256 intrinsicValue
    ) internal pure returns (int256[] memory payouts) {
        payouts = new int256[](pois.length);

        for (uint256 i; i < strikes.length;) {
            payouts = payouts.add(pois.subEachBy(strikes[i]).maximum(0).eachMulDivDown(weights[i], sUNIT));

            unchecked {
                ++i;
            }
        }

        payouts =
            payouts.add(pois.subEachBy(spotPrice).eachMulDivDown(syntheticUnderlyingWeight, sUNIT)).addEachBy(intrinsicValue);
    }

    /**
     * @notice calculate slope
     * @dev used to calculate directionality of the payout profile
     * @param leftPoint coordinates of x,y
     * @param rightPoint coordinates of x,y
     * @return direction positive or negative
     */
    function _calcSlope(int256[] memory leftPoint, int256[] memory rightPoint) internal pure returns (int256) {
        if (leftPoint[0] > rightPoint[0]) revert CM_InvalidPoints();
        if (leftPoint.length != 2) revert CM_InvalidLeftPointLength();
        if (leftPoint.length != 2) revert CM_InvalidRightPointLength();

        return (((rightPoint[1] - leftPoint[1]) * sUNIT) / (rightPoint[0] - leftPoint[0]));
    }

    /**
     * @notice computes the slope to the right of the right most strike (call options), resulting in the delta hedge (underlying)
     * @param pois points of interest (strikes)
     * @param payouts payouts at coorisponding pois
     * @return underlyingNeeded amount of underlying needed
     * @return rightDelta the slope
     */
    function _getUnderlyingNeeded(uint256[] memory pois, int256[] memory payouts)
        internal
        pure
        returns (uint256 underlyingNeeded, int256 rightDelta)
    {
        int256[] memory leftPoint = new int256[](2);
        leftPoint[0] = pois.at(-2).toInt256();
        leftPoint[1] = payouts.at(-2);

        int256[] memory rightPoint = new int256[](2);
        rightPoint[0] = pois.at(-1).toInt256();
        rightPoint[1] = payouts.at(-1);

        // slope
        rightDelta = _calcSlope(leftPoint, rightPoint);
        underlyingNeeded = rightDelta < sZERO ? uint256(-rightDelta) : ZERO;
    }

    /**
     * @notice computes the slope to the left of the left most strike (put options)
     * @dev only called if there are put options, usually denominated in cash
     * @param putStrikes put option strikes
     * @param putWeights number of put options at a coorisponding strike
     * @return numeraireNeeded amount of numeraire asset needed
     */
    function _getNumeraireNeeded(uint256[] memory putStrikes, int256[] memory putWeights)
        internal
        pure
        returns (uint256 numeraireNeeded)
    {
        int256 tmpNumeraireNeeded = putStrikes.dot(putWeights) / sUNIT;

        numeraireNeeded = tmpNumeraireNeeded < sZERO ? uint256(-tmpNumeraireNeeded) : ZERO;
    }

    /**
     * @notice crediting the numeraire if underlying has a positive payout
     * @dev checks if subAccount has positive underlying value, if it does then cash requirements can be lowered
     * @param pois option strikes
     * @param payouts payouts at coorisponding pois
     * @param numeraireNeeded current numeraire needed
     * @param underlyingNeeded underlying needed
     * @param hasPuts has put options
     * @return numeraireNeeded adjusted numerarie needed
     */
    function _getUnderlyingAdjustedNumeraireNeeded(
        uint256[] memory pois,
        int256[] memory payouts,
        uint256 numeraireNeeded,
        uint256 underlyingNeeded,
        bool hasPuts
    ) internal pure returns (uint256) {
        // only evaluate actual strikes (left and right most strikes are evauluating directionality)
        int256 minStrikePayout = -payouts.slice(hasPuts ? int256(1) : sZERO, -1).min();

        if (numeraireNeeded.toInt256() < minStrikePayout) {
            (, uint256 index) = payouts.indexOf(-minStrikePayout);
            uint256 underlyingPayoutAtMinStrike = (pois[index] * underlyingNeeded) / UNIT;

            if (underlyingPayoutAtMinStrike.toInt256() > minStrikePayout) numeraireNeeded = ZERO;
            else numeraireNeeded = uint256(minStrikePayout) - underlyingPayoutAtMinStrike; // check directly above means minStrikePayout > 0
        }

        return numeraireNeeded;
    }

    /**
     * @notice converts numerarie needed entirely in underlying
     * @dev only used if options collateralizied in underlying
     * @param _detail margin details
     * @param pois option strikes
     * @param payouts payouts at coorisponding pois
     * @param strikes option strikes without testing strikes
     * @param syntheticUnderlyingWeight sum of put positions (negative)
     * @param underlyingNeeded current underlying needed
     * @param hasPuts has put options
     * @return inUnderlyingOnly bool if it can be done
     * @return underlyingOnlyNeeded adjusted underlying needed
     */
    function _checkHedgableTailRisk(
        CrossMarginDetail memory _detail,
        uint256[] memory pois,
        int256[] memory payouts,
        uint256[] memory strikes,
        int256 syntheticUnderlyingWeight,
        uint256 underlyingNeeded,
        bool hasPuts
    ) internal pure returns (bool inUnderlyingOnly, uint256 underlyingOnlyNeeded) {
        int256 minPutPayout;
        uint256 startPos = hasPuts ? 1 : 0;

        if (_detail.putStrikes.length > 0) minPutPayout = _calcPutPayouts(_detail.putStrikes, _detail.putWeights).min();

        int256 valueAtFirstStrike;

        if (hasPuts) valueAtFirstStrike = -syntheticUnderlyingWeight * int256(strikes[0]) + payouts[startPos];

        inUnderlyingOnly = valueAtFirstStrike + minPutPayout >= sZERO;

        if (inUnderlyingOnly) {
            // shifting pois if there is a left of leftmost, removing right of rightmost, adding underlyingNeeded at the end
            // ie: pois.length - startPos - 1 + 1
            int256[] memory negPayoutsOverPois = new int256[](pois.length - startPos);

            for (uint256 i = startPos; i < pois.length - 1;) {
                negPayoutsOverPois[i - startPos] = (-payouts[i] * sUNIT) / int256(pois[i]);

                unchecked {
                    ++i;
                }
            }
            negPayoutsOverPois[negPayoutsOverPois.length - 1] = underlyingNeeded.toInt256();

            int256 tmpUnderlyingOnlyNeeded = negPayoutsOverPois.max();

            underlyingOnlyNeeded = tmpUnderlyingOnlyNeeded > 0 ? uint256(tmpUnderlyingOnlyNeeded) : ZERO;
        }
    }

    /**
     * @notice calculate put option payouts at each point of interest
     * @dev only called if there are put options
     * @param strikes concatentated array of shorts and longs
     * @param weights number of options at each strike
     * @return putPayouts payouts for a put options at a coorisponding strike
     */
    function _calcPutPayouts(uint256[] memory strikes, int256[] memory weights)
        internal
        pure
        returns (int256[] memory putPayouts)
    {
        putPayouts = new int256[](strikes.length);

        for (uint256 i; i < strikes.length;) {
            putPayouts = putPayouts.add(strikes.subEachFrom(strikes[i]).maximum(0).eachMul(weights[i]));

            unchecked {
                ++i;
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                         Setup CrossMarginDetail
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice  converts Position struct arrays to in-memory detail struct arrays
     */
    function _getPositionDetails(IGrappa grappa, Position[] calldata shorts, Position[] calldata longs)
        internal
        view
        returns (CrossMarginDetail[] memory details)
    {
        details = new CrossMarginDetail[](0);

        // used to reference which detail struct should be updated for a given position
        bytes32[] memory usceLookUp = new bytes32[](0);

        Position[] memory positions = shorts.concat(longs);
        uint256 shortLength = shorts.length;

        for (uint256 i; i < positions.length;) {
            (, uint40 productId, uint64 expiry,,) = positions[i].tokenId.parseTokenId();

            ProductDetails memory product = _getProductDetails(grappa, productId);

            bytes32 pos = keccak256(abi.encode(product.underlyingId, product.strikeId, expiry));

            (bool found, uint256 index) = ArrayUtil.indexOf(usceLookUp, pos);

            CrossMarginDetail memory detail;

            if (found) {
                detail = details[index];
            } else {
                usceLookUp = ArrayUtil.append(usceLookUp, pos);

                detail.underlyingId = product.underlyingId;
                detail.underlyingDecimals = product.underlyingDecimals;
                detail.numeraireId = product.strikeId;
                detail.numeraireDecimals = product.strikeDecimals;
                detail.spotPrice = IOracle(product.oracle).getSpotPrice(product.underlying, product.strike);
                detail.expiry = expiry;

                details = details.append(detail);
            }

            int256 amount = int256(int64(positions[i].amount));
            if (i < shortLength) amount = -amount;

            _processDetailWithToken(detail, positions[i].tokenId, amount);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice merges option and amounts into the set
     * @dev if weight turns into zero, we remove it from the set
     */
    function _processDetailWithToken(CrossMarginDetail memory detail, uint256 tokenId, int256 amount) internal pure {
        (TokenType tokenType,,, uint64 strike,) = tokenId.parseTokenId();

        bool found;
        uint256 index;

        // adjust or append to callStrikes array or callWeights array.
        if (tokenType == TokenType.CALL) {
            (found, index) = detail.callStrikes.indexOf(strike);

            if (found) {
                detail.callWeights[index] += amount;

                if (detail.callWeights[index] == 0) {
                    detail.callWeights = detail.callWeights.remove(index);
                    detail.callStrikes = detail.callStrikes.remove(index);
                }
            } else {
                detail.callStrikes = detail.callStrikes.append(strike);
                detail.callWeights = detail.callWeights.append(amount);
            }
        } else if (tokenType == TokenType.PUT) {
            // adjust or append to putStrikes array or putWeights array.
            (found, index) = detail.putStrikes.indexOf(strike);

            if (found) {
                detail.putWeights[index] += amount;

                if (detail.putWeights[index] == 0) {
                    detail.putWeights = detail.putWeights.remove(index);
                    detail.putStrikes = detail.putStrikes.remove(index);
                }
            } else {
                detail.putStrikes = detail.putStrikes.append(strike);
                detail.putWeights = detail.putWeights.append(amount);
            }
        }
    }

    /**
     * @notice gets product asset specific details from grappa in one call
     */
    function _getProductDetails(IGrappa grappa, uint40 productId) internal view returns (ProductDetails memory info) {
        (,, uint8 underlyingId, uint8 strikeId,) = ProductIdUtil.parseProductId(productId);

        (address oracle,, address underlying, uint8 underlyingDecimals, address strike, uint8 strikeDecimals,,) =
            grappa.getDetailFromProductId(productId);

        info.oracle = oracle;
        info.underlying = underlying;
        info.underlyingId = underlyingId;
        info.underlyingDecimals = underlyingDecimals;
        info.strike = strike;
        info.strikeId = strikeId;
        info.strikeDecimals = strikeDecimals;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IGrappa} from "../../../interfaces/IGrappa.sol";
import {IERC20} from "lib/grappa/lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import "../../../libraries/TokenIdUtil.sol";
import "../../../libraries/ProductIdUtil.sol";
import "../../../libraries/BalanceUtil.sol";
import "../../../libraries/ArrayUtil.sol";

import "../../../config/types.sol";
import "../../../config/constants.sol";

// Cross Margin libraries and configs
import "./AccountUtil.sol";
import "./types.sol";
import "./errors.sol";

/**
 * @title CrossMarginLib
 * @dev   This library is in charge of updating the simple account struct and do validations
 */
library CrossMarginLib {
    using BalanceUtil for Balance[];
    using AccountUtil for Position[];
    using AccountUtil for PositionOptim[];
    using ArrayUtil for uint256[];
    using ProductIdUtil for uint40;
    using TokenIdUtil for uint256;
    using TokenIdUtil for uint192;

    /**
     * @dev return true if the account has no short,long positions nor collateral
     */
    function isEmpty(CrossMarginAccount storage account) external view returns (bool) {
        return account.shorts.sum() == 0 && account.longs.sum() == 0 && account.collaterals.sum() == 0;
    }

    ///@dev Increase the collateral in the account
    ///@param account CrossMarginAccount storage that will be updated
    function addCollateral(CrossMarginAccount storage account, uint8 collateralId, uint80 amount) public {
        if (amount == 0) return;

        (bool found, uint256 index) = account.collaterals.indexOf(collateralId);

        if (!found) {
            account.collaterals.push(Balance(collateralId, amount));
        } else {
            account.collaterals[index].amount += amount;
        }
    }

    ///@dev Reduce the collateral in the account
    ///@param account CrossMarginAccount storage that will be updated
    function removeCollateral(CrossMarginAccount storage account, uint8 collateralId, uint80 amount) public {
        Balance[] memory collaterals = account.collaterals;

        (bool found, uint256 index) = collaterals.indexOf(collateralId);

        if (!found) revert CM_WrongCollateralId();

        uint80 newAmount = collaterals[index].amount - amount;

        if (newAmount == 0) {
            account.collaterals.remove(index);
        } else {
            account.collaterals[index].amount = newAmount;
        }
    }

    ///@dev Increase the amount of short call or put (debt) of the account
    ///@param account CrossMarginAccount storage that will be updated
    function mintOption(CrossMarginAccount storage account, uint256 tokenId, uint64 amount) external {
        if (amount == 0) return;

        (TokenType optionType, uint40 productId,,,) = tokenId.parseTokenId();

        // assign collateralId or check collateral id is the same
        (,, uint8 underlyingId, uint8 strikeId, uint8 collateralId) = productId.parseProductId();

        // engine only supports calls and puts
        if (optionType != TokenType.CALL && optionType != TokenType.PUT) revert CM_UnsupportedTokenType();

        // call can only collateralized by underlying
        if ((optionType == TokenType.CALL) && underlyingId != collateralId) {
            revert CM_CannotMintOptionWithThisCollateral();
        }

        // put can only be collateralized by strike
        if ((optionType == TokenType.PUT) && strikeId != collateralId) revert CM_CannotMintOptionWithThisCollateral();

        (bool found, uint256 index) = account.shorts.getPositions().indexOf(tokenId);
        if (!found) {
            account.shorts.pushPosition(Position(tokenId, amount));
        } else {
            account.shorts[index].amount += amount;
        }
    }

    ///@dev Remove the amount of short call or put (debt) of the account
    ///@param account CrossMarginAccount storage that will be updated in-place
    function burnOption(CrossMarginAccount storage account, uint256 tokenId, uint64 amount) external {
        (bool found, PositionOptim memory position, uint256 index) = account.shorts.find(tokenId.compress());

        if (!found) revert CM_InvalidToken();

        uint64 newShortAmount = position.amount - amount;
        if (newShortAmount == 0) {
            account.shorts.removePositionAt(index);
        } else {
            account.shorts[index].amount = newShortAmount;
        }
    }

    ///@dev Increase the amount of long call or put (debt) of the account
    ///@param account CrossMarginAccount storage that will be updated
    function addOption(CrossMarginAccount storage account, uint256 tokenId, uint64 amount) external {
        if (amount == 0) return;

        (bool found, uint256 index) = account.longs.indexOf(tokenId.compress());

        if (!found) {
            account.longs.pushPosition(Position(tokenId, amount));
        } else {
            account.longs[index].amount += amount;
        }
    }

    ///@dev Remove the amount of long call or put held by the account
    ///@param account CrossMarginAccount storage that will be updated in-place
    function removeOption(CrossMarginAccount storage account, uint256 tokenId, uint64 amount) external {
        (bool found, PositionOptim memory position, uint256 index) = account.longs.find(tokenId.compress());

        if (!found) revert CM_InvalidToken();

        uint64 newLongAmount = position.amount - amount;
        if (newLongAmount == 0) {
            account.longs.removePositionAt(index);
        } else {
            account.longs[index].amount = newLongAmount;
        }
    }

    ///@dev Settles the accounts longs and shorts
    ///@param account CrossMarginAccount storage that will be updated in-place
    function settleAtExpiry(CrossMarginAccount storage account, IGrappa grappa)
        external
        returns (Balance[] memory longPayouts, Balance[] memory shortPayouts)
    {
        // settling longs first as they can only increase collateral
        longPayouts = _settleLongs(grappa, account);
        // settling shorts last as they can only reduce collateral
        shortPayouts = _settleShorts(grappa, account);
    }

    ///@dev Settles the accounts longs, adding collateral to balances
    ///@param grappa interface to settle long options in a batch call
    ///@param account CrossMarginAccount memory that will be updated in-place
    function _settleLongs(IGrappa grappa, CrossMarginAccount storage account) public returns (Balance[] memory payouts) {
        uint256 i;
        uint256[] memory tokenIds;
        uint256[] memory amounts;

        while (i < account.longs.length) {
            uint256 tokenId = account.longs[i].tokenId.expand();

            if (tokenId.isExpired()) {
                tokenIds = tokenIds.append(tokenId);
                amounts = amounts.append(account.longs[i].amount);

                account.longs.removePositionAt(i);
            } else {
                unchecked {
                    ++i;
                }
            }
        }

        if (tokenIds.length > 0) {
            payouts = grappa.batchSettleOptions(address(this), tokenIds, amounts);

            for (i = 0; i < payouts.length;) {
                // add the collateral in the account storage.
                addCollateral(account, payouts[i].collateralId, payouts[i].amount);

                unchecked {
                    ++i;
                }
            }
        }
    }

    ///@dev Settles the accounts shorts, reserving collateral for ITM options
    ///@param grappa interface to get short option payouts in a batch call
    ///@param account CrossMarginAccount memory that will be updated in-place
    function _settleShorts(IGrappa grappa, CrossMarginAccount storage account) public returns (Balance[] memory payouts) {
        uint256 i;
        uint256[] memory tokenIds;
        uint256[] memory amounts;

        while (i < account.shorts.length) {
            uint256 tokenId = account.shorts[i].tokenId.expand();

            if (tokenId.isExpired()) {
                tokenIds = tokenIds.append(tokenId);
                amounts = amounts.append(account.shorts[i].amount);

                account.shorts.removePositionAt(i);
            } else {
                unchecked {
                    ++i;
                }
            }
        }

        if (tokenIds.length > 0) {
            payouts = grappa.batchGetPayouts(tokenIds, amounts);

            for (i = 0; i < payouts.length;) {
                // remove the collateral in the account storage.
                removeCollateral(account, payouts[i].collateralId, payouts[i].amount);

                unchecked {
                    ++i;
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

///@dev unit used for option amount and strike prices
uint8 constant UNIT_DECIMALS = 6;

///@dev unit scaled used to convert amounts.
uint256 constant UNIT = 10 ** 6;

///@dev int scaled used to convert amounts.
int256 constant sUNIT = int256(10 ** 6);

///@dev basis point for 100%.
uint256 constant BPS = 10000;

///@dev uint zero
uint256 constant ZERO = 0;

/// @dev int zero
int256 constant sZERO = int256(0);

///@dev maximum dispute period for oracle
uint256 constant MAX_DISPUTE_PERIOD = 6 hours;

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../interfaces/draft-IERC1822.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
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
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
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
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

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
pragma solidity ^0.8.0;

import "../config/types.sol";

interface IGrappa {
    function getDetailFromProductId(uint40 _productId)
        external
        view
        returns (
            address oracle,
            address engine,
            address underlying,
            uint8 underlyingDecimals,
            address strike,
            uint8 strikeDecimals,
            address collateral,
            uint8 collateralDecimals
        );

    function checkEngineAccess(uint256 _tokenId, address _engine) external view;

    function checkEngineAccessAndTokenId(uint256 _tokenId, address _engine) external view;

    function engineIds(address _engine) external view returns (uint8 id);

    function assets(uint8 _id) external view returns (address addr, uint8 decimals);

    function engines(uint8 _id) external view returns (address engine);

    function oracles(uint8 _id) external view returns (address oracle);

    function getPayout(uint256 tokenId, uint64 amount)
        external
        view
        returns (address engine, address collateral, uint256 payout);

    /**
     * @notice burn option token and get out cash value at expiry
     * @param _account who to settle for
     * @param _tokenId  tokenId of option token to burn
     * @param _amount   amount to settle
     * @return payout amount paid out
     */
    function settleOption(address _account, uint256 _tokenId, uint256 _amount) external returns (uint256 payout);

    /**
     * @notice burn array of option tokens and get out cash value at expiry
     * @param _account who to settle for
     * @param _tokenIds array of tokenIds to burn
     * @param _amounts   array of amounts to burn
     */
    function batchSettleOptions(address _account, uint256[] memory _tokenIds, uint256[] memory _amounts)
        external
        returns (Balance[] memory payouts);

    function batchGetPayouts(uint256[] memory _tokenIds, uint256[] memory _amounts) external returns (Balance[] memory payouts);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOptionToken {
    /**
     * @dev mint option token to an address. Can only be called by corresponding margin engine
     * @param _recipient    where to mint token to
     * @param _tokenId      tokenId to mint
     * @param _amount       amount to mint
     *
     */
    function mint(address _recipient, uint256 _tokenId, uint256 _amount) external;

    /**
     * @dev burn option token from an address. Can only be called by corresponding margin engine
     * @param _from         account to burn from
     * @param _tokenId      tokenId to burn
     * @param _amount       amount to burn
     *
     */
    function burn(address _from, uint256 _tokenId, uint256 _amount) external;

    /**
     * @dev burn option token from an address. Can only be called by grappa, used for settlement
     * @param _from         account to burn from
     * @param _tokenId      tokenId to burn
     * @param _amount       amount to burn
     *
     */
    function burnGrappaOnly(address _from, uint256 _tokenId, uint256 _amount) external;

    /**
     * @dev burn batch of option token from an address. Can only be called by grappa
     * @param _from         account to burn from
     * @param _ids          tokenId to burn
     * @param _amounts      amount to burn
     *
     */
    function batchBurnGrappaOnly(address _from, uint256[] memory _ids, uint256[] memory _amounts) external;
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
pragma solidity ^0.8.0;

library NumberUtil {
    /**
     * @dev use it in uncheck so overflow will still be checked.
     */
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(x == 0 || (x * y) / x == y)
            if iszero(or(iszero(x), eq(div(z, x), y))) { revert(0, 0) }
        }
    }

    /**
     * @notice convert decimals of an amount
     *
     * @param  amount      number to convert
     * @param fromDecimals the decimals amount has
     * @param toDecimals   the target decimals
     *
     * @return newAmount number with toDecimals decimals
     */
    function convertDecimals(uint256 amount, uint8 fromDecimals, uint8 toDecimals) internal pure returns (uint256) {
        if (fromDecimals == toDecimals) return amount;

        if (fromDecimals > toDecimals) {
            uint8 diff;
            unchecked {
                diff = fromDecimals - toDecimals;
                // div cannot underflow because diff 10**diff != 0
                return amount / (10 ** diff);
            }
        } else {
            uint8 diff;
            unchecked {
                diff = toDecimals - fromDecimals;
            }
            return amount * (10 ** diff);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// external librares
import {ERC1155} from "lib/grappa/lib/solmate/src/tokens/ERC1155.sol";

// interfaces
import {IOptionToken} from "../interfaces/IOptionToken.sol";
import {IGrappa} from "../interfaces/IGrappa.sol";
import {IOptionTokenDescriptor} from "../interfaces/IOptionTokenDescriptor.sol";

import {TokenIdUtil} from "../libraries/TokenIdUtil.sol";
import {ProductIdUtil} from "../libraries/ProductIdUtil.sol";

// constants and types
import "../config/enums.sol";
import "../config/constants.sol";
import "../config/errors.sol";

/**
 * @title   OptionToken
 * @author  antoncoding
 * @dev     each OptionToken represent the right to redeem cash value at expiry.
 *             The value of each OptionType should always be positive.
 */
contract OptionToken is ERC1155, IOptionToken {
    ///@dev grappa serve as the registry
    IGrappa public immutable grappa;
    IOptionTokenDescriptor public immutable descriptor;

    constructor(address _grappa, address _descriptor) {
        // solhint-disable-next-line reason-string
        if (_grappa == address(0)) revert();
        grappa = IGrappa(_grappa);

        descriptor = IOptionTokenDescriptor(_descriptor);
    }

    /**
     *  @dev return string as defined in token descriptor
     *
     */
    function uri(uint256 id) public view override returns (string memory) {
        return descriptor.tokenURI(id);
    }

    /**
     * @dev mint option token to an address. Can only be called by corresponding margin engine
     * @param _recipient    where to mint token to
     * @param _tokenId      tokenId to mint
     * @param _amount       amount to mint
     */
    function mint(address _recipient, uint256 _tokenId, uint256 _amount) external override {
        grappa.checkEngineAccessAndTokenId(_tokenId, msg.sender);

        _mint(_recipient, _tokenId, _amount, "");
    }

    /**
     * @dev burn option token from an address. Can only be called by corresponding margin engine
     * @param _from         account to burn from
     * @param _tokenId      tokenId to burn
     * @param _amount       amount to burn
     *
     */
    function burn(address _from, uint256 _tokenId, uint256 _amount) external override {
        grappa.checkEngineAccess(_tokenId, msg.sender);

        _burn(_from, _tokenId, _amount);
    }

    /**
     * @dev burn option token from an address. Can only be called by grappa, used for settlement
     * @param _from         account to burn from
     * @param _tokenId      tokenId to burn
     * @param _amount       amount to burn
     *
     */
    function burnGrappaOnly(address _from, uint256 _tokenId, uint256 _amount) external override {
        _checkIsGrappa();
        _burn(_from, _tokenId, _amount);
    }

    /**
     * @dev burn batch of option token from an address. Can only be called by grappa, used for settlement
     * @param _from         account to burn from
     * @param _ids          tokenId to burn
     * @param _amounts      amount to burn
     *
     */
    function batchBurnGrappaOnly(address _from, uint256[] memory _ids, uint256[] memory _amounts) external override {
        _checkIsGrappa();
        _batchBurn(_from, _ids, _amounts);
    }

    /**
     * @dev check if msg.sender is the marginAccount
     */
    function _checkIsGrappa() internal view {
        if (msg.sender != address(grappa)) revert NoAccess();
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Minimalist and gas efficient standard ERC1155 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    /*//////////////////////////////////////////////////////////////
                             ERC1155 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                             METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                              ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual {
        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual {
        require(ids.length == amounts.length, "LENGTH_MISMATCH");

        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        // Storing these outside the loop saves ~15 gas per iteration.
        uint256 id;
        uint256 amount;

        for (uint256 i = 0; i < ids.length; ) {
            id = ids[i];
            amount = amounts[i];

            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids)
        public
        view
        virtual
        returns (uint256[] memory balances)
    {
        require(owners.length == ids.length, "LENGTH_MISMATCH");

        balances = new uint256[](owners.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < owners.length; ++i) {
                balances[i] = balanceOf[owners[i]][ids[i]];
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, address(0), to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, address(0), id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[to][ids[i]] += amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, address(0), ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchBurn(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[from][ids[i]] -= amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        balanceOf[from][id] -= amount;

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155TokenReceiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Describes Option NFT
interface IOptionTokenDescriptor {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// imported contracts and libraries
import {FixedPointMathLib} from "lib/grappa/lib/solmate/src/utils/FixedPointMathLib.sol";

import {SafeCast} from "lib/grappa/lib/openzeppelin-contracts/contracts/utils/math/SafeCast.sol";
import {UUPSUpgradeable} from "lib/grappa/lib/openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "lib/grappa/lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "lib/grappa/lib/openzeppelin-contracts-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol";

// interfaces
import {IERC20Metadata} from "lib/grappa/lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IOracle} from "../interfaces/IOracle.sol";
import {IOptionToken} from "../interfaces/IOptionToken.sol";
import {IGrappa} from "../interfaces/IGrappa.sol";
import {IMarginEngine} from "../interfaces/IMarginEngine.sol";

// librarise
import {BalanceUtil} from "../libraries/BalanceUtil.sol";
import {MoneynessLib} from "../libraries/MoneynessLib.sol";
import {NumberUtil} from "../libraries/NumberUtil.sol";
import {ProductIdUtil} from "../libraries/ProductIdUtil.sol";
import {TokenIdUtil} from "../libraries/TokenIdUtil.sol";

// constants and types
import "../config/types.sol";
import "../config/enums.sol";
import "../config/constants.sol";
import "../config/errors.sol";

/**
 * @title   Grappa
 * @author  @antoncoding, @dsshap
 * @dev     This contract serves as the registry of the system who system.
 */
contract Grappa is OwnableUpgradeable, ReentrancyGuardUpgradeable, UUPSUpgradeable {
    using BalanceUtil for Balance[];
    using FixedPointMathLib for uint256;
    using NumberUtil for uint256;
    using ProductIdUtil for uint40;
    using SafeCast for uint256;
    using TokenIdUtil for uint256;

    /// @dev optionToken address
    IOptionToken public immutable optionToken;

    /*///////////////////////////////////////////////////////////////
                         State Variables V1
    //////////////////////////////////////////////////////////////*/

    /// @dev next id used to represent an address
    /// invariant:  any id in tokenId not greater than this number
    uint8 public nextAssetId;

    /// @dev next id used to represent an address
    /// invariant:  any id in tokenId not greater than this number
    uint8 public nextengineId;

    /// @dev next id used to represent an address
    /// invariant:  any id in tokenId not greater than this number
    uint8 public nextOracleId;

    /// @dev assetId => asset address
    mapping(uint8 => AssetDetail) public assets;

    /// @dev engineId => margin engine address
    mapping(uint8 => address) public engines;

    /// @dev oracleId => oracle address
    mapping(uint8 => address) public oracles;

    /// @dev address => assetId
    mapping(address => uint8) public assetIds;

    /// @dev address => engineId
    mapping(address => uint8) public engineIds;

    /// @dev address => oracleId
    mapping(address => uint8) public oracleIds;

    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/

    event OptionSettled(address account, uint256 tokenId, uint256 amountSettled, uint256 payout);
    event AssetRegistered(address asset, uint8 id);
    event MarginEngineRegistered(address engine, uint8 id);
    event OracleRegistered(address oracle, uint8 id);

    /*///////////////////////////////////////////////////////////////
                Constructor for implementation Contract
    //////////////////////////////////////////////////////////////*/

    /// @dev set immutables in constructor
    /// @dev also set the implemention contract to initialized = true
    constructor(address _optionToken) initializer {
        optionToken = IOptionToken(_optionToken);
    }

    /*///////////////////////////////////////////////////////////////
                            Initializer
    //////////////////////////////////////////////////////////////*/

    function initialize() external initializer {
        __Ownable_init();
    }

    /*///////////////////////////////////////////////////////////////
                    Override Upgrade Permission
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Upgradable by the owner.
     *
     */
    function _authorizeUpgrade(address /*newImplementation*/ ) internal view override {
        _checkOwner();
    }

    /*///////////////////////////////////////////////////////////////
                            External Functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev parse product id into composing asset and engine addresses
     * @param _productId product id
     */
    function getDetailFromProductId(uint40 _productId)
        public
        view
        returns (
            address oracle,
            address engine,
            address underlying,
            uint8 underlyingDecimals,
            address strike,
            uint8 strikeDecimals,
            address collateral,
            uint8 collateralDecimals
        )
    {
        (uint8 oracleId, uint8 engineId, uint8 underlyingId, uint8 strikeId, uint8 collateralId) =
            ProductIdUtil.parseProductId(_productId);
        AssetDetail memory underlyingDetail = assets[underlyingId];
        AssetDetail memory strikeDetail = assets[strikeId];
        AssetDetail memory collateralDetail = assets[collateralId];
        return (
            oracles[oracleId],
            engines[engineId],
            underlyingDetail.addr,
            underlyingDetail.decimals,
            strikeDetail.addr,
            strikeDetail.decimals,
            collateralDetail.addr,
            collateralDetail.decimals
        );
    }

    /**
     * @dev parse token id into composing option details
     * @param _tokenId product id
     */
    function getDetailFromTokenId(uint256 _tokenId)
        external
        pure
        returns (TokenType tokenType, uint40 productId, uint64 expiry, uint64 longStrike, uint64 shortStrike)
    {
        return TokenIdUtil.parseTokenId(_tokenId);
    }

    /**
     * @notice    get product id from underlying, strike and collateral address
     * @dev       function will still return even if some of the assets are not registered
     * @param _underlying  underlying address
     * @param _strike      strike address
     * @param _collateral  collateral address
     */
    function getProductId(address _oracle, address _engine, address _underlying, address _strike, address _collateral)
        external
        view
        returns (uint40 id)
    {
        id = ProductIdUtil.getProductId(
            oracleIds[_oracle], engineIds[_engine], assetIds[_underlying], assetIds[_strike], assetIds[_collateral]
        );
    }

    /**
     * @notice    get token id from type, productId, expiry, strike
     * @dev       function will still return even if some of the assets are not registered
     * @param _tokenType TokenType enum
     * @param _productId if of the product
     * @param _expiry timestamp of option expiry
     * @param _longStrike strike price of the long option, with 6 decimals
     * @param _shortStrike strike price of the short (upper bond for call and lower bond for put) if this is a spread. 6 decimals
     */
    function getTokenId(TokenType _tokenType, uint40 _productId, uint256 _expiry, uint256 _longStrike, uint256 _shortStrike)
        external
        pure
        returns (uint256 id)
    {
        id = TokenIdUtil.getTokenId(_tokenType, _productId, _expiry, _longStrike, _shortStrike);
    }

    /**
     * @notice burn option token and get out cash value at expiry
     *
     * @param _account  who to settle for
     * @param _tokenId  tokenId of option token to burn
     * @param _amount   amount to settle
     */
    function settleOption(address _account, uint256 _tokenId, uint256 _amount) external nonReentrant returns (uint256) {
        (address engine, address collateral, uint256 payout) = getPayout(_tokenId, _amount.toUint64());

        emit OptionSettled(_account, _tokenId, _amount, payout);

        optionToken.burnGrappaOnly(_account, _tokenId, _amount);

        IMarginEngine(engine).payCashValue(collateral, _account, payout);

        return payout;
    }

    /**
     * @notice burn array of option tokens and get out cash value at expiry
     *
     * @param _account who to settle for
     * @param _tokenIds array of tokenIds to burn
     * @param _amounts   array of amounts to burn
     */
    function batchSettleOptions(address _account, uint256[] memory _tokenIds, uint256[] memory _amounts)
        external
        nonReentrant
        returns (Balance[] memory payouts)
    {
        if (_tokenIds.length != _amounts.length) revert GP_WrongArgumentLength();

        if (_tokenIds.length == 0) return payouts;

        optionToken.batchBurnGrappaOnly(_account, _tokenIds, _amounts);

        address lastCollateral;
        address lastEngine;

        uint256 lastTotalPayout;

        for (uint256 i; i < _tokenIds.length;) {
            (address engine, address collateral, uint256 payout) = getPayout(_tokenIds[i], _amounts[i].toUint64());

            uint8 collateralId = _tokenIds[i].parseCollateralId();

            payouts = _addToPayouts(payouts, collateralId, payout);

            // if engine or collateral changes, payout and clear temporary parameters
            if (lastEngine == address(0)) {
                lastEngine = engine;
                lastCollateral = collateral;
            } else if (engine != lastEngine || lastCollateral != collateral) {
                IMarginEngine(lastEngine).payCashValue(lastCollateral, _account, lastTotalPayout);
                lastTotalPayout = 0;
                lastEngine = engine;
                lastCollateral = collateral;
            }
            emit OptionSettled(_account, _tokenIds[i], _amounts[i], payout);

            unchecked {
                lastTotalPayout = lastTotalPayout + payout;
                ++i;
            }
        }

        IMarginEngine(lastEngine).payCashValue(lastCollateral, _account, lastTotalPayout);
    }

    /**
     * @dev calculate the payout for one option token
     *
     * @param _tokenId  token id of option token
     * @param _amount   amount to settle
     *
     * @return engine engine to settle
     * @return collateral asset to settle in
     * @return payout amount paid
     *
     */
    function getPayout(uint256 _tokenId, uint64 _amount)
        public
        view
        returns (address engine, address collateral, uint256 payout)
    {
        uint256 payoutPerOption;
        (engine, collateral, payoutPerOption) = _getPayoutPerToken(_tokenId);
        payout = payoutPerOption * _amount;
        unchecked {
            payout = payout / UNIT;
        }
    }

    /**
     * @dev calculate the payout for array of options
     *
     * @param _tokenIds array of token id
     * @param _amounts  array of amount
     *
     * @return payouts amounts paid
     *
     */
    function batchGetPayouts(uint256[] memory _tokenIds, uint256[] memory _amounts)
        external
        view
        returns (Balance[] memory payouts)
    {
        for (uint256 i; i < _tokenIds.length;) {
            (,, uint256 payout) = getPayout(_tokenIds[i], _amounts[i].toUint64());

            uint8 collateralId = _tokenIds[i].parseCollateralId();
            payouts = _addToPayouts(payouts, collateralId, payout);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev revert if _engine doesn't have access to mint / burn a tokenId;
     * @param _tokenId tokenid
     * @param _engine address intending to mint / burn
     */
    function checkEngineAccess(uint256 _tokenId, address _engine) external view {
        // create check engine access
        uint8 engineId = TokenIdUtil.parseEnginelId(_tokenId);
        if (_engine != engines[engineId]) revert GP_Not_Authorized_Engine();
    }

    /**
     * @dev revert if _engine doesn't have access to mint or the tokenId is invalid.
     * @param _tokenId tokenid
     * @param _engine address intending to mint / burn
     */
    function checkEngineAccessAndTokenId(uint256 _tokenId, address _engine) external view {
        // check tokenId
        _isValidTokenIdToMint(_tokenId);

        //  check engine access
        uint8 engineId = _tokenId.parseEnginelId();
        if (_engine != engines[engineId]) revert GP_Not_Authorized_Engine();
    }

    /*///////////////////////////////////////////////////////////////
                            Admin Functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev register an asset to be used as strike/underlying
     * @param _asset address to add
     *
     */
    function registerAsset(address _asset) external returns (uint8 id) {
        _checkOwner();

        if (assetIds[_asset] != 0) revert GP_AssetAlreadyRegistered();

        uint8 decimals = IERC20Metadata(_asset).decimals();

        id = ++nextAssetId;
        assets[id] = AssetDetail({addr: _asset, decimals: decimals});
        assetIds[_asset] = id;

        emit AssetRegistered(_asset, id);
    }

    /**
     * @dev register an engine to create / settle options
     * @param _engine address of the new margin engine
     *
     */
    function registerEngine(address _engine) external returns (uint8 id) {
        _checkOwner();

        if (engineIds[_engine] != 0) revert GP_EngineAlreadyRegistered();

        id = ++nextengineId;
        engines[id] = _engine;

        engineIds[_engine] = id;

        emit MarginEngineRegistered(_engine, id);
    }

    /**
     * @dev register an oracle to report prices
     * @param _oracle address of the new oracle
     *
     */
    function registerOracle(address _oracle) external returns (uint8 id) {
        _checkOwner();

        if (oracleIds[_oracle] != 0) revert GP_OracleAlreadyRegistered();

        // this is a soft check on whether an oracle is suitable to be used.
        if (IOracle(_oracle).maxDisputePeriod() > MAX_DISPUTE_PERIOD) revert GP_BadOracle();

        id = ++nextOracleId;
        oracles[id] = _oracle;

        oracleIds[_oracle] = id;

        emit OracleRegistered(_oracle, id);
    }

    /* =====================================
     *          Internal Functions
     * ====================================**/

    /**
     * @dev make sure that the tokenId make sense
     */
    function _isValidTokenIdToMint(uint256 _tokenId) internal view {
        (TokenType optionType,, uint64 expiry, uint64 longStrike, uint64 shortStrike) = _tokenId.parseTokenId();

        // check option type and strikes
        // check that vanilla options doesnt have a shortStrike argument
        if ((optionType == TokenType.CALL || optionType == TokenType.PUT) && (shortStrike != 0)) revert GP_BadStrikes();

        // check that you cannot mint a "credit spread" token
        if (optionType == TokenType.CALL_SPREAD && (shortStrike < longStrike)) revert GP_BadStrikes();
        if (optionType == TokenType.PUT_SPREAD && (shortStrike > longStrike)) revert GP_BadStrikes();

        // check expiry
        if (expiry <= block.timestamp) revert GP_InvalidExpiry();
    }

    /**
     * @dev calculate the payout for one option token
     *
     * @param _tokenId  token id of option token
     *
     * @return engine engine to settle
     * @return collateral asset to settle in
     * @return payoutPerOption amount paid
     *
     */
    function _getPayoutPerToken(uint256 _tokenId) internal view returns (address, address, uint256 payoutPerOption) {
        (TokenType tokenType, uint40 productId, uint64 expiry, uint64 longStrike, uint64 shortStrike) =
            TokenIdUtil.parseTokenId(_tokenId);

        if (block.timestamp < expiry) revert GP_NotExpired();

        (address oracle, address engine, address underlying,, address strike,, address collateral, uint8 collateralDecimals) =
            getDetailFromProductId(productId);

        // expiry price of underlying, denominated in strike (usually USD), with {UNIT_DECIMALS} decimals
        uint256 expiryPrice = _getSettlementPrice(oracle, underlying, strike, expiry);

        // cash value denominated in strike (usually USD), with {UNIT_DECIMALS} decimals
        uint256 cashValue;
        if (tokenType == TokenType.CALL) {
            cashValue = MoneynessLib.getCallCashValue(expiryPrice, longStrike);
        } else if (tokenType == TokenType.CALL_SPREAD) {
            cashValue = MoneynessLib.getCashValueDebitCallSpread(expiryPrice, longStrike, shortStrike);
        } else if (tokenType == TokenType.PUT) {
            cashValue = MoneynessLib.getPutCashValue(expiryPrice, longStrike);
        } else if (tokenType == TokenType.PUT_SPREAD) {
            cashValue = MoneynessLib.getCashValueDebitPutSpread(expiryPrice, longStrike, shortStrike);
        }

        // the following logic convert cash value (amount worth) if collateral is not strike:
        if (collateral == underlying) {
            // collateral is underlying. payout should be devided by underlying price
            cashValue = cashValue.mulDivDown(UNIT, expiryPrice);
        } else if (collateral != strike) {
            // collateral is not underlying nor strike
            uint256 collateralPrice = _getSettlementPrice(oracle, collateral, strike, expiry);
            cashValue = cashValue.mulDivDown(UNIT, collateralPrice);
        }
        payoutPerOption = cashValue.convertDecimals(UNIT_DECIMALS, collateralDecimals);

        return (engine, collateral, payoutPerOption);
    }

    /**
     * @dev add an entry to array of Balance
     * @param payouts existing payout array
     * @param collateralId new collateralId
     * @param payout new payout
     */
    function _addToPayouts(Balance[] memory payouts, uint8 collateralId, uint256 payout)
        internal
        pure
        returns (Balance[] memory)
    {
        if (payout == 0) return payouts;

        (bool found, uint256 index) = payouts.indexOf(collateralId);
        if (!found) {
            payouts = payouts.append(Balance(collateralId, payout.toUint80()));
        } else {
            payouts[index].amount += payout.toUint80();
        }

        return payouts;
    }

    /**
     * @dev check settlement price is finalized from oracle, and return price
     * @param _oracle oracle contract address
     * @param _base base asset (ETH is base asset while requesting ETH / USD)
     * @param _quote quote asset (USD is base asset while requesting ETH / USD)
     * @param _expiry expiry timestamp
     */
    function _getSettlementPrice(address _oracle, address _base, address _quote, uint256 _expiry)
        internal
        view
        returns (uint256)
    {
        (uint256 price, bool isFinalized) = IOracle(_oracle).getPriceAtExpiry(_base, _quote, _expiry);
        if (!isFinalized) revert GP_PriceNotFinalized();
        return price;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {FixedPointMathLib} from "lib/grappa/lib/solmate/src/utils/FixedPointMathLib.sol";

import "../config/types.sol";
import "../config/constants.sol";

/**
 * @title MoneynessLib
 * @dev Library to calculate the moneyness of options
 */
library MoneynessLib {
    using FixedPointMathLib for uint256;

    /**
     * @notice   get the cash value of a call option strike
     * @dev      returns max(spot - strike, 0)
     * @param spot  spot price in usd term with 6 decimals
     * @param strike strike price in usd term with 6 decimals
     *
     */
    function getCallCashValue(uint256 spot, uint256 strike) internal pure returns (uint256) {
        unchecked {
            return spot < strike ? 0 : spot - strike;
        }
    }

    /**
     * @notice   get the cash value of a put option strike
     * @dev      returns max(strike - spot, 0)
     * @param spot spot price in usd term with 6 decimals
     * @param strike strike price in usd term with 6 decimals
     *
     */
    function getPutCashValue(uint256 spot, uint256 strike) internal pure returns (uint256) {
        unchecked {
            return spot > strike ? 0 : strike - spot;
        }
    }

    /**
     * @notice  get the cash value of a debit call spread
     * @dev     retuns min(max(spot - strike, 0), shortStrike - longStrike)
     * @dev     expect long strike to be lower than short strike
     * @param spot spot price
     * @param longStrike strike price of the long call
     * @param shortStrike strike price of the short call
     */
    function getCashValueDebitCallSpread(uint256 spot, uint256 longStrike, uint256 shortStrike) internal pure returns (uint256) {
        // assume long strike is lower than short strike.
        unchecked {
            if (spot > shortStrike) return shortStrike - longStrike;
            // expired itm, capped at (short - long)
            else if (spot > longStrike) return spot - longStrike;
            // expired itm
            else return 0;
        }
    }

    /**
     * @notice  get the cash value of a debit put spread
     * @dev     retuns min(max(strike - spot, 0), longStrike - shortStrike)
     * @dev     expect long strike to be higher than short strike
     * @param spot spot price
     * @param longStrike strike price of the long put
     * @param longStrike strike price of the short put
     */
    function getCashValueDebitPutSpread(uint256 spot, uint256 longStrike, uint256 shortStrike) internal pure returns (uint256) {
        unchecked {
            if (spot < shortStrike) return longStrike - shortStrike;
            // expired itm, capped at (long - short)
            else if (spot < longStrike) return longStrike - spot;
            // expired itm
            else return 0;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.4;

import { Grappa } from "../../lib/grappa/src/core/Grappa.sol";
import { OptionToken } from "../../lib/grappa/src/core/OptionToken.sol";
import { CrossMarginLib } from "../../lib/grappa/src/core/engines/cross-margin/CrossMarginLib.sol";
import { CrossMarginMath } from "../../lib/grappa/src/core/engines/cross-margin/CrossMarginMath.sol";
import { CrossMarginEngine } from "../../lib/grappa/src/core/engines/cross-margin/CrossMarginEngine.sol";

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { FixedPointMathLib } from "solmate/src/utils/FixedPointMathLib.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import { IWhitelist } from "../interfaces/IWhitelist.sol";
import { IHashnoteOptionsVault } from "../interfaces/IHashnoteOptionsVault.sol";
import "../interfaces/IBatchAuction.sol";

import "../libraries/BatchAuctionQ.sol";
import "../storage/BatchAuctionStorage.sol";

import "../utils/Error.sol";

/**
 * @title BatchAuction
 * @notice The batch auction is designed for a seller to be able to list and sell multiple options at once as a structure. An auction is created for some period
 * in which bidders will be able to place bids on the available structures. Placing a bid may require the bidder to pay or receive a premium and post collateral, depending on the price.
 * When the auction has ended and has been settled, the premium and collateral collected is transferred to the seller, which will then be used to mint the various options within each of the structures sold.
 *
 * After settlement, any users who had successful bids will be able to claim the options their entitled to within each structure, and a partial premium refund paying the difference between their bid price
 * and the clearing price. Those users who only had partly successful bids, or completely unsuccessful bids will have those bids premium & collateral returned.
 */
contract BatchAuction is Ownable, BatchAuctionStorage, ReentrancyGuard {
    using FixedPointMathLib for uint256;
    using BatchAuctionQ for BatchAuctionQ.Queue;
    using SafeERC20 for IERC20;

    // Each option token within grappa has a precision of 10^6
    uint8 internal constant UNIT_DECIMALS = 6;
    uint256 internal constant UNIT = 10**6;

    event NewAuction(
        uint256 auctionId,
        address seller,
        address optionTokenAddr,
        uint256[] optionTokens,
        address biddingToken,
        IBatchAuction.Collateral[] collaterals,
        int256 minPrice,
        uint256 minBidSize,
        uint256 totalSize,
        uint256 endTime
    );

    event NewBid(uint256 indexed auctionId, address indexed user, uint256 quantity, int256 price);

    event SettleAuction(uint256 auctionId, int256 clearingPrice, uint256 totalSold);

    event Claimed(uint256 indexed auctionId, address indexed user, uint256 quantity, int256 price);

    constructor() {}

    /*///////////////////////////////////////////////////////////////
                        External Functions
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice Allows a seller to create an auction with the given parameters
     *  @param optionTokenAddr the option token address
     *  @param optionTokens list of tokens ids within the structure being minted. Each id contains serialized information about the option
     *  @param biddingToken in which premiums will be paid for the structure
     *  @param collaterals that may be required to be posted by the bidder in order to mint the structures
     *  @param minPrice which a bid will be accepted by the auction. If the bid is positive, the bidder will pay the premium, if it's negative, the seller will pay the premium
     *  @param minBidSize minimum amount of structures a user can bid for
     *  @param totalSize amount of structures being listed for auction
     *  @param endTime end of the auction
     *  @param whitelist only approved bidders can enter and claim their proceeds
     *  @return auctionId generated for this auction
     */
    function createAuction(
        address optionTokenAddr,
        uint256[] calldata optionTokens,
        address biddingToken,
        IBatchAuction.Collateral[] calldata collaterals,
        int96 minPrice,
        uint64 minBidSize,
        uint64 totalSize,
        uint256 endTime,
        address whitelist
    ) external returns (uint256 auctionId) {
        if (optionTokenAddr == address(0)) revert BA_BadOptionAddress();
        if (optionTokens.length == 0) revert BA_BadOptions();
        if (biddingToken == address(0)) revert BA_BadBiddingAddress();
        if (minBidSize > totalSize) revert BA_BadSize();
        if (block.timestamp >= endTime) revert BA_BadTime();

        auctionsCounter += 1;
        auctionId = auctionsCounter;

        for (uint256 i; i < collaterals.length; ) {
            if (collaterals[i].addr == address(0)) revert BA_BadCollateral();
            if (collaterals[i].amount == 0) revert BA_BadAmount();

            // No duplicate collaterals
            for (uint256 j = i + 1; j < collaterals.length; ) {
                if (collaterals[i].addr == collaterals[j].addr) revert BA_BadCollateral();

                unchecked {
                    ++j;
                }
            }

            auctions[auctionId].collaterals.push(collaterals[i]);

            unchecked {
                ++i;
            }
        }

        auctions[auctionId].seller = msg.sender;
        auctions[auctionId].optionTokenAddr = optionTokenAddr;
        auctions[auctionId].optionTokens = optionTokens;
        auctions[auctionId].biddingToken = biddingToken;
        auctions[auctionId].minPrice = minPrice;
        auctions[auctionId].minBidSize = minBidSize;
        auctions[auctionId].totalSize = totalSize;
        auctions[auctionId].availableSize = totalSize;
        auctions[auctionId].endTime = endTime;
        auctions[auctionId].whitelist = whitelist;

        emit NewAuction(
            auctionId,
            msg.sender,
            optionTokenAddr,
            optionTokens,
            biddingToken,
            collaterals,
            minPrice,
            minBidSize,
            totalSize,
            endTime
        );
    }

    /**
     * @notice Allows a user to bid on a structure listed at a particular auction. Any collaterals and premiums will be withdrew from the bidder depending upon the quantity. If the price is negative,
     * then only collaterals will be taken as it will be the seller paying the premium instead.
     * @param auctionId of the auction they wish to place the bid
     * @param quantity quantity The number of structures the user wishes to bid for
     * @param price The positive price is how much the bidder is willing to pay, the negative price how much the bidder is willing to be paid
     */
    function placeBid(
        uint256 auctionId,
        uint256 quantity,
        int256 price
    ) external nonReentrant {
        //Only whitelisted accounts can place a bid
        _checkPermissions(auctionId);

        IBatchAuction.Auction storage auction = auctions[auctionId];

        if (auction.totalSize == 0) revert BA_Uninitialized();
        if (block.timestamp >= auction.endTime) revert BA_AuctionClosed();
        if (quantity < auction.minBidSize) revert BA_BadAmount();
        if (price < auction.minPrice) revert BA_BadPrice();
        BatchAuctionQ.Queue storage queue = queues[auctionId];

        queue.insert(msg.sender, price, quantity);

        // transfer collateral to auction if the bid is positive, any premiums from successful negative price bids will be paid upon claiming after the auction has settled
        if (price > 0) transferPremium(auction.biddingToken, address(this), price, quantity);

        // transfer total collateral for the required structures to the auction
        transferCollateral(auction.collaterals, address(this), quantity);

        emit NewBid(auctionId, msg.sender, quantity, price);
    }

    /**
     * @param auctionId required to look up the whitelist address attached to that auction
     */
    function _checkPermissions(uint256 auctionId) internal view {
        address whitelist = auctions[auctionId].whitelist;
        if (whitelist != address(0)) {
            //Revert tx if user is not whitelisted
            if (!IWhitelist(whitelist).isLP(msg.sender)) revert BA_Unauthorized();
        }
    }

    /**
     * @notice Allows a user to remove their bid within an auction and receive the initial premium & collateral paid
     * @param auctionId the auction to remove the bid
     * @param bidId to be removed
     */
    function removeBid(uint256 auctionId, uint256 bidId) external {
        _checkPermissions(auctionId);

        IBatchAuction.Auction storage auction = auctions[auctionId];
        BatchAuctionQ.Queue storage queue = queues[auctionId];

        // check bidId in range
        if (bidId >= queue.bidOwnerList.length) revert BA_Unauthorized();
        // check sender is the owner
        if (msg.sender != queue.bidOwnerList[bidId]) revert BA_Unauthorized();
        // check if auction already closed
        if (block.timestamp >= auction.endTime) revert BA_AuctionClosed();

        // grab these values into memory before wiping them
        uint256 quantity = queue.bidQuantityList[bidId];
        int256 price = queue.bidPriceList[bidId];

        // remove from queue, delets from bidOwnerList, so can not be repeated
        queue.remove(bidId);

        // refund premium
        if (price > 0) transferPremium(auction.biddingToken, msg.sender, price, quantity);

        // refund collateral
        transferCollateral(auction.collaterals, msg.sender, quantity);
    }

    /**
     * @notice Allows auction to be settled, transferring any premiums and collaterals collected to the seller
     * @param auctionId of the auction to to be settled
     * @return clearingPrice the auction was cleared at, which is the cheapest filled bid price
     * @return totalSold the total number of structures sold
     */
    function settleAuction(uint256 auctionId) external nonReentrant returns (int256 clearingPrice, uint256 totalSold) {
        IBatchAuction.Auction storage auction = auctions[auctionId];

        uint256 totalSize = auction.availableSize;

        if (totalSize == 0) revert BA_EmptyAuction();
        if (block.timestamp <= auction.endTime) revert BA_AuctionNotClosed();
        if (auction.settled) revert BA_AuctionSettled();
        if (auction.seller != msg.sender) revert BA_Unauthorized();

        BatchAuctionQ.Queue storage queue = queues[auctionId];

        auction.settled = true;

        address seller = auction.seller;

        if (queue.bidOwnerList.length > 0) (clearingPrice, totalSold) = queue.computeFills(totalSize);

        if (totalSold > 0) {
            auction.availableSize -= totalSold;

            address recipient;

            if (clearingPrice > 0) recipient = seller;
            else if (clearingPrice < 0) recipient = address(this);

            // proceeds are equal to fill amount times clearing price
            if (recipient != address(0)) transferPremium(auction.biddingToken, recipient, clearingPrice, totalSold);

            //transfer the collateral from the successfully filled bids to the seller
            transferCollateral(auction.collaterals, seller, totalSold);
        }

        emit SettleAuction(auctionId, clearingPrice, totalSold);
    }

    /**
     *  @notice Claims any proceeds and refunds from the auction
     *  @param auctionId the auction to claim the proceeds
     */
    function claim(uint256 auctionId) external nonReentrant {
        IBatchAuction.Auction storage auction = auctions[auctionId];

        if (!auction.settled) revert BA_AuctionUnsettled();

        BatchAuctionQ.Queue storage queue = queues[auctionId];

        int256 clearingPrice = queue.clearingPrice;

        uint256 totalPremiumRefund;
        uint256 totalCollateralRefund;
        uint256 totalFilled;

        for (uint256 i; i < queue.bidOwnerList.length; ) {
            // only loop through this user's bids
            if (queue.bidOwnerList[i] == msg.sender) {
                int256 price = queue.bidPriceList[i];
                uint256 quantity = queue.bidQuantityList[i];
                uint256 fill = queue.filledAmount[i];

                // if bid wins
                if (fill > 0) {
                    // get premium refund if applicable
                    // note: price >= clearingPrice always because fill>0
                    uint256 refundPremium = computePremium(price - clearingPrice, fill);

                    // for bubble bidder, return premium for amount not won
                    if (fill < quantity) {
                        uint256 unfilledQuantity;

                        unchecked {
                            unfilledQuantity = quantity - fill;
                        }

                        // refund premium
                        refundPremium += computePremium(price, unfilledQuantity);

                        // refund collateral
                        totalCollateralRefund += unfilledQuantity;
                    }

                    // if bid.price positive issue refund, if negative pay bidder premium for all the structures they got filled on
                    if (price > 0) totalPremiumRefund += refundPremium;
                    else if (price < 0) totalPremiumRefund += computePremium(clearingPrice, fill);

                    // add to total filled to novate at the end
                    totalFilled += fill;
                } else {
                    // if did not win, refund entre bid
                    if (price > 0) totalPremiumRefund += computePremium(price, quantity);

                    // get collateral refund
                    totalCollateralRefund += quantity;
                }

                // remove bid from queue
                queue.remove(i);

                emit Claimed(auctionId, msg.sender, quantity, price);
            }

            unchecked {
                ++i;
            }
        }

        // assign options and collateral from vault subAccount to user subAccount in Grappa
        if (totalFilled > 0)
            IHashnoteOptionsVault(auction.seller).novate(
                msg.sender,
                totalFilled,
                auction.optionTokens,
                _getCollateralPerShareAmounts(auction.collaterals)
            );

        // after checking all bids, refund totaled premium
        if (totalPremiumRefund > 0) IERC20(auction.biddingToken).safeTransfer(msg.sender, totalPremiumRefund);

        // after checking all bids, refund totaled collateral(s)
        if (totalCollateralRefund > 0) transferCollateral(auction.collaterals, msg.sender, totalCollateralRefund);
    }

    /*///////////////////////////////////////////////////////////////
                        External DApp Helper Functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @param auctionId of the auction
     * @return bidPriceList the list of prices
     * @return bidQuantityList the list of quantities
     * @return bidOwnerList the list of owners
     * @return filledAmount the list of filled
     */
    function getBids(uint256 auctionId)
        external
        view
        returns (
            int256[] memory bidPriceList,
            uint256[] memory bidQuantityList,
            address[] memory bidOwnerList,
            uint256[] memory filledAmount
        )
    {
        BatchAuctionQ.Queue storage queue = queues[auctionId];

        return (queue.bidPriceList, queue.bidQuantityList, queue.bidOwnerList, queue.filledAmount);
    }

    /**
     * @notice gets the list of filled amounts
     * @param auctionId of the auction
     * @return filledAmount the list of bids which were filled and their amounts
     */
    function getFills(uint256 auctionId) external view returns (uint256[] memory filledAmount) {
        BatchAuctionQ.Queue storage queue = queues[auctionId];

        filledAmount = queue.filledAmount;
    }

    /**
     * @notice gets the clearing price
     * @param auctionId of the auction
     * @return clearingPrice of the auction, which is equal to the lowest priced bid that was filled
     */
    function getClearingPrice(uint256 auctionId) external view returns (int256 clearingPrice) {
        IBatchAuction.Auction storage auction = auctions[auctionId];
        BatchAuctionQ.Queue storage queue = queues[auctionId];

        if (!auction.settled) revert BA_AuctionSettled();
        clearingPrice = queue.clearingPrice;
    }

    /**
     * @notice gets the options within each structure being auctioned
     * @param auctionId of the auction
     * @return optionTokens that make up the structure being auctioned
     */
    function getOptionTokens(uint256 auctionId) external view returns (uint256[] memory optionTokens) {
        IBatchAuction.Auction storage auction = auctions[auctionId];

        optionTokens = auction.optionTokens;
    }

    /**
     * @param auctionId of the auction
     * @return collaterals that the bidder has deposited
     */
    function getBidderCollaterals(uint256 auctionId)
        external
        view
        returns (IBatchAuction.Collateral[] memory collaterals)
    {
        IBatchAuction.Auction storage auction = auctions[auctionId];

        collaterals = auction.collaterals;
    }

    receive() external payable {
        revert();
    }

    fallback() external payable {
        revert();
    }

    /*///////////////////////////////////////////////////////////////
                        Internal Functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @param price of each structure
     * @param quantity of structures
     * @return premium required
     */
    function computePremium(int256 price, uint256 quantity) internal pure returns (uint256 premium) {
        premium = toUint256(price).mulDivDown(quantity, UNIT);
    }

    /**
     * @notice Calculates and transfers the premium from a user to the contract if depositing, or from the contract to a user when withdrawing
     * @param tokenAddr of the premium to transfer
     * @param recipient the receiver of the premium
     * @param price to calculate how much to transfer
     * @param quantity to calculate how much to transfer
     */
    function transferPremium(
        address tokenAddr,
        address recipient,
        int256 price,
        uint256 quantity
    ) internal {
        bool isWithdraw = recipient != address(this);

        uint256 premium;

        if (isWithdraw) premium = toUint256(price).mulDivDown(quantity, UNIT);
        else premium = toUint256(price).mulDivUp(quantity, UNIT);

        IERC20 token = IERC20(tokenAddr);

        if (isWithdraw) token.safeTransfer(recipient, premium);
        else token.safeTransferFrom(msg.sender, address(this), premium);
    }

    /**
     * @notice Transfers the collateral from a user to the contract if depositing, or from the contract to a user when withdrawing
     * @param collaterals to transfer
     * @param recipient the receiver
     * @param quantity how many to transfer
     */
    function transferCollateral(
        IBatchAuction.Collateral[] memory collaterals,
        address recipient,
        uint256 quantity
    ) internal {
        bool isWithdraw = recipient != address(this);

        //Transfer the collateral from the bidder to the auction
        for (uint256 i = 0; i < collaterals.length; ) {
            // collateral per token * quantity
            // this disourages bidding for "too much size" but we can allow it for simplicity sake
            uint256 amount;

            if (isWithdraw) amount = quantity.mulDivDown(collaterals[i].amount, UNIT);
            else amount = quantity.mulDivUp(collaterals[i].amount, UNIT);

            if (amount > 0) {
                IERC20 token = IERC20(collaterals[i].addr);

                if (isWithdraw) token.safeTransfer(recipient, amount);
                else token.safeTransferFrom(msg.sender, address(this), amount);
            }

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Retrieves all the amounts from the list of collaterals required per share
     * @param collaterals to retrieve the amounts from
     * @return amounts collateral amounts
     */
    function _getCollateralPerShareAmounts(IBatchAuction.Collateral[] storage collaterals)
        internal
        view
        returns (uint256[] memory amounts)
    {
        amounts = new uint256[](collaterals.length);

        for (uint256 i; i < collaterals.length; ) {
            amounts[i] = collaterals[i].amount;

            unchecked {
                ++i;
            }
        }
    }

    function toUint256(int256 variable) internal pure returns (uint256) {
        return (variable < 0) ? uint256(-variable) : uint256(variable);
    }
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

// SPDX-License-Identifier: MIT

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
     * by making the `nonReentrant` function external, and make it call a
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.4;

import "../interfaces/IBatchAuction.sol";
import "../libraries/BatchAuctionQ.sol";

abstract contract BatchAuctionStorageV1 {
    // Counter to keep track number of auctions
    uint256 public auctionsCounter;
    // Mapping of auction details for a given auctionId
    mapping(uint256 => IBatchAuction.Auction) public auctions;
    // Mapping of auction bid queue for a given auctionId
    mapping(uint256 => BatchAuctionQ.Queue) internal queues;
    // Mapping of a users balance for a given auctionId
    mapping(uint256 => mapping(address => uint256)) internal balances;
    // Mapping of a users collateral balances for a given auctionId
    mapping(uint256 => mapping(address => mapping(address => uint256))) internal collateralBalances;
}

// We are following Compound's method of upgrading new contract implementations
// When we need to add new storage variables, we create a new version of BatchAuctionStorage
// e.g. BatchAuctionStorage<versionNumber>, so finally it would look like
// contract BatchAuctionStorage is BatchAuctionStorageV1, BatchAuctionStorageV2
abstract contract BatchAuctionStorage is BatchAuctionStorageV1 {

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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { IHashnoteOptionsVault } from "../interfaces/IHashnoteOptionsVault.sol";
import { IBatchAuction } from "../interfaces/IBatchAuction.sol";
import { IERC1155Receiver } from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

contract MockAuctionSeller {
    address payable auctionAddress;
    address tokenAddress;
    address optionTokenAddress;

    event Novate(address recipient, uint256 amount, uint256[] options, uint256[] counterparty);

    constructor(
        address payable _auctionAddress,
        address payable _tokenAddress,
        address _optionTokenAddress
    ) {
        auctionAddress = _auctionAddress;
        tokenAddress = _tokenAddress;
        optionTokenAddress = _optionTokenAddress;
    }

    function novate(
        address recipient,
        uint256 amount,
        uint256[] calldata options,
        uint256[] calldata counterparty
    ) external {
        IERC1155 optionToken = IERC1155(optionTokenAddress);
        // convert to batch!
        for (uint256 i; i < options.length; ) {
            uint256 tokenId = options[i];

            if (optionToken.balanceOf(address(this), tokenId) >= amount) {
                optionToken.safeTransferFrom(address(this), recipient, tokenId, amount, bytes(""));
            }

            unchecked {
                ++i;
            }
        }

        emit Novate(recipient, amount, options, counterparty);
    }

    function createAuction(
        address optionTokenAddr,
        uint256[] calldata optionTokens,
        address biddingToken,
        IBatchAuction.Collateral[] calldata collaterals,
        int96 minPrice,
        uint64 minBidSize,
        uint64 totalSize,
        uint256 endTime,
        address whitelist
    ) public {
        IBatchAuction(auctionAddress).createAuction(
            optionTokenAddr,
            optionTokens,
            biddingToken,
            collaterals,
            minPrice,
            minBidSize,
            totalSize,
            endTime,
            whitelist
        );
    }

    function settleAuction(uint256 auctionId) public {
        IBatchAuction(auctionAddress).settleAuction(auctionId);
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function approve(address addr, uint256 quantity) external {
        IERC20(tokenAddress).approve(addr, quantity);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
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

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(_msgSender() != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `account` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][account] += amount;
        emit TransferSingle(operator, address(0), account, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 accountBalance = _balances[id][account];
        require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][account] = accountBalance - amount;
        }

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 accountBalance = _balances[id][account];
            require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][account] = accountBalance - amount;
            }
        }

        emit TransferBatch(operator, account, address(0), ids, amounts);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {}

    function mint(address to, uint256 value) public virtual {
        _mint(to, value);
    }

    function burn(address from, uint256 value) public virtual {
        _burn(from, value);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract MockERC1155 is ERC1155 {
    constructor() ERC1155("") {}

    function mint(address to, uint256 id, uint256 amount) external {
        _mint(to, id, amount, bytes(""));
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.4;

import { VaultLifecycle } from "../libraries/VaultLifecycle.sol";
import { Vault } from "../libraries/Vault.sol";

contract TestVaultLifecycle {
    Vault.VaultState public vaultState;

    /**
     * @notice Calculates the next day/hour of the week
     * @param timestamp is the expiry timestamp of the current option
     * @param dayOfWeek is the day of the week we're looking for (sun:0/7 - sat:6), 8 will be treated as wil and the next available hourOfDay will be returned
     * @param hourOfDay is the next hour of the day we want to expire on (midnight:0)
     *
     * Examples when day = 5, hour = 8:
     * getNextDayTimeOfWeek(week 1 thursday) -> week 1 friday:0800
     * getNextDayTimeOfWeek(week 1 friday) -> week 2 friday:0800
     * getNextDayTimeOfWeek(week 1 saturday) -> week 2 friday:0800
     *
     * Examples when day = 7, hour = 8:
     * getNextDayTimeOfWeek(week 1 thursday) -> week 1 friday:0800
     * getNextDayTimeOfWeek(week 1 friday:0500) -> week 1 friday:0800
     * getNextDayTimeOfWeek(week 1 friday:0900) -> week 1 saturday:0800
     * getNextDayTimeOfWeek(week 1 saturday) -> week 1 sunday:0800
     */
    function getNextDayTimeOfWeek(
        uint256 timestamp,
        uint256 dayOfWeek,
        uint256 hourOfDay
    ) internal pure returns (uint256) {
        // we want sunday to have a vaule of 7
        if (dayOfWeek == 0) dayOfWeek = 7;

        // dayOfWeek = 0 (sunday) - 6 (saturday) calculated from epoch time
        uint256 timestampDayOfWeek = ((timestamp / 1 days) + 4) % 7;
        //Calculate the nextDayOfWeek by figuring out how much time is between now and then in seconds
        uint256 nextDayOfWeek = timestamp +
            ((7 + (dayOfWeek == 8 ? timestampDayOfWeek : dayOfWeek) - timestampDayOfWeek) % 7) *
            1 days;
        //Calculate the nextStartTime by removing the seconds past midnight, then adding the amount seconds after midnight we wish to start
        uint256 nextStartTime = nextDayOfWeek - (nextDayOfWeek % 24 hours) + (hourOfDay * 1 hours);

        // If the date has passed, we simply increment it by a week to get the next dayOfWeek, or by a day if we only want the next hourOfDay
        if (timestamp >= nextStartTime) {
            dayOfWeek == 8 ? nextStartTime += 1 days : nextStartTime += 7 days;
        }

        return nextStartTime;
    }

    /**
     * @notice Gets the next option expiry timestamp
     * @param roundConfig the configuration used to calculate the option expiry
     */
    function getNextExpiry(uint256 timestamp, Vault.RoundConfig calldata roundConfig) external pure returns (uint256) {
        uint256 offset = timestamp + roundConfig.duration;

        // The offset will always be greater than the options expiry, so we subtract a week in order to get the day the option should expire, or subtract a day to get the hour the option should start if the dayOfWeek is wild (8)
        if (roundConfig.dayOfWeek != 8) {
            offset -= 1 weeks;
        } else {
            offset -= 1 days;
        }

        uint256 nextTime = getNextDayTimeOfWeek(offset, roundConfig.dayOfWeek, roundConfig.hourOfDay);

        //if timestamp is in the past relative to the offset, it means we've tried to calculate an expiry of an option which has too short of length. I.e trying to run a 1 day option on a Tuesday which should expire Friday
        require(nextTime >= offset, "Option period is too short to land on the configured expiry date");

        return nextTime;
    }

    function balanceOf(address account) public view returns (uint256) {
        if (account == address(this)) {
            return 1 ether;
        }
        return 0;
    }

    function setVaultState(Vault.VaultState calldata newVaultState) public {
        vaultState.totalPending = newVaultState.totalPending;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.4;

import { ShareMath } from "../libraries/ShareMath.sol";

contract TestShareMath {
    function navToShares(uint256 assetAmount, uint256 pps) external pure returns (uint256) {
        return ShareMath.navToShares(assetAmount, pps);
    }

    function sharesToAsset(uint256 shares, uint256 pps) external pure returns (uint256) {
        return ShareMath.sharesToNAV(shares, pps);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.4;
import { Vault } from "../libraries/Vault.sol";

interface IHashnoteVault {
    function deposit(uint256 amount) external;

    function depositETH() external payable;

    function cap() external view returns (uint256);

    function depositFor(uint256 amount, address creditor) external;

    function vaultParams() external view returns (Vault.VaultParams memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.4;

import "../libraries/BatchAuctionQ.sol";

contract TestBatchAuctionQ {
    using BatchAuctionQ for BatchAuctionQ.Queue;

    BatchAuctionQ.Queue internal queue;

    function isEmpty() public view returns (bool) {
        return queue.isEmpty();
    }

    function insert(
        address owner,
        int256 price,
        uint256 quantity
    ) public {
        queue.insert(owner, price, quantity);
    }

    function remove(uint256 index) public {
        queue.remove(index);
    }

    function getBidPriceList() public view returns (int256[] memory) {
        return queue.bidPriceList;
    }

    function getBidQuantityList() public view returns (uint256[] memory) {
        return queue.bidQuantityList;
    }

    function getBidAddresses() public view returns (address[] memory) {
        return queue.bidOwnerList;
    }

    function getFills() public view returns (uint256[] memory) {
        return queue.filledAmount;
    }

    function computeFills(uint64 totalSize) public {
        queue.computeFills(totalSize);
    }

    function getClearingPrice() public view returns (int256) {
        return queue.clearingPrice;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../utils/Error.sol";

/// @notice a min priority queue implementation, based off https://algs4.cs.princeton.edu/24pq/MinPQ.java.html
library BatchAuctionMPQ {
    struct Bid {
        uint256 bidId;
        address owner;
        int256 price;
        uint256 quantity;
    }

    struct Queue {
        ///@notice incrementing bid id
        uint256 nextBidId;
        ///@notice array backing priority queue
        uint256[] bidIdList;
        ///@notice total number of bids in queue
        uint256 numBids;
        //@notice map bid ids to bids
        mapping(uint256 => Bid) bidIdToBidMap;
        ///@notice map addreses to bids they own
        mapping(address => uint256[]) ownerToBidIds;
    }

    ///@notice initialize must be called before using queue.
    function initialize(Queue storage self) public {
        self.bidIdList.push(0);
        self.nextBidId = 1;
    }

    function isEmpty(Queue storage self) public view returns (bool) {
        return self.numBids == 0;
    }

    function getNumBids(Queue storage self) public view returns (uint256) {
        return self.numBids;
    }

    ///@notice view min bid
    function getMin(Queue storage self) public view returns (Bid storage) {
        if (isEmpty(self)) revert BA_Uninitialized();
        uint256 minId = self.bidIdList[1];
        return self.bidIdToBidMap[minId];
    }

    ///@notice move bid up heap
    function swim(Queue storage self, uint256 k) private {
        while (k > 1 && isGreater(self, k / 2, k)) {
            exchange(self, k, k / 2);
            k = k / 2;
        }
    }

    ///@notice move bid down heap
    function sink(Queue storage self, uint256 k) private {
        while (2 * k <= self.numBids) {
            uint256 j = 2 * k;
            if (j < self.numBids && isGreater(self, j, j + 1)) {
                ++j;
            }
            if (!isGreater(self, k, j)) {
                break;
            }
            exchange(self, k, j);
            k = j;
        }
    }

    ///@notice insert bid in heap
    function insert(Queue storage self, address owner, int256 price, uint256 quantity) public {
        insert(self, Bid(self.nextBidId++, owner, price, quantity));
    }

    ///@notice insert bid in heap
    function insert(Queue storage self, Bid memory bid) private {
        self.bidIdList.push(bid.bidId);
        self.bidIdToBidMap[bid.bidId] = bid;
        self.numBids += 1;
        swim(self, self.numBids);
        self.ownerToBidIds[bid.owner].push(bid.bidId);
    }

    ///@notice delete min bid from heap and return
    function delMin(Queue storage self) public returns (Bid memory) {
        if (isEmpty(self)) revert BA_Uninitialized();
        Bid memory min = self.bidIdToBidMap[self.bidIdList[1]];
        exchange(self, 1, self.numBids--);
        self.bidIdList.pop();
        delete self.bidIdToBidMap[min.bidId];
        sink(self, 1);
        uint256[] storage curUserBids = self.ownerToBidIds[min.owner];
        for (uint256 i; i < curUserBids.length; ) {
            if (curUserBids[i] == min.bidId) {
                //remove from array and delete struct
                curUserBids[i] = curUserBids[curUserBids.length - 1];
                curUserBids.pop();
                break;
            }
            unchecked {
                ++i;
            }
        }
        return min;
    }

    ///@notice helper function to determine ordering. When two bids have the same price, give priority
    ///to the one with the larger quantity
    function isGreater(Queue storage self, uint256 i, uint256 j) private view returns (bool) {
        Bid memory bidI = self.bidIdToBidMap[self.bidIdList[i]];
        Bid memory bidJ = self.bidIdToBidMap[self.bidIdList[j]];
        if (bidI.price == bidJ.price) {
            return bidI.quantity < bidJ.quantity;
        }
        return bidI.price > bidJ.price;
    }

    ///@notice helper function to exchange to bids in the heap
    function exchange(Queue storage self, uint256 i, uint256 j) private {
        uint256 tempId = self.bidIdList[i];
        self.bidIdList[i] = self.bidIdList[j];
        self.bidIdList[j] = tempId;
    }
}