// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import { MathUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import { SafeCastUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import { SignedMathUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/math/SignedMathUpgradeable.sol";

import { ERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import { EnumerableSetUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import { TrancheData, TrancheDataHelpers, BondHelpers } from "./_utils/BondHelpers.sol";

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { IERC20MetadataUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import { ITranche } from "./_interfaces/buttonwood/ITranche.sol";
import { IBondController } from "./_interfaces/buttonwood/IBondController.sol";

import { IPerpetualTranche } from "./_interfaces/IPerpetualTranche.sol";
import { IBondIssuer } from "./_interfaces/IBondIssuer.sol";
import { IFeeStrategy } from "./_interfaces/IFeeStrategy.sol";
import { IPricingStrategy } from "./_interfaces/IPricingStrategy.sol";
import { IYieldStrategy } from "./_interfaces/IYieldStrategy.sol";

/// @notice Expected bond issuer to not be `address(0)`.
error UnacceptableBondIssuer();

/// @notice Expected fee strategy to not be `address(0)`.
error UnacceptableFeeStrategy();

/// @notice Expected pricing strategy to not be `address(0)`.
error UnacceptablePricingStrategy();

/// @notice Expected pricing strategy to return a fixed point with exactly {PRICE_DECIMALS} decimals.
error InvalidPricingStrategyDecimals();

/// @notice Expected yield strategy to not be `address(0)`.
error UnacceptableYieldStrategy();

/// @notice Expected yield strategy to return a fixed point with exactly {YIELD_DECIMALS} decimals.
error InvalidYieldStrategyDecimals();

/// @notice Expected skim percentage to be less than 100 with {PERC_DECIMALS}.
/// @param skimPerc The skim percentage.
error UnacceptableSkimPerc(uint256 skimPerc);

/// @notice Expected minTrancheMaturity be less than or equal to maxTrancheMaturity.
/// @param minTrancheMaturiySec Minimum tranche maturity time in seconds.
/// @param minTrancheMaturiySec Maximum tranche maturity time in seconds.
error InvalidTrancheMaturityBounds(uint256 minTrancheMaturiySec, uint256 maxTrancheMaturiySec);

/// @notice Expected transfer out asset to not be a reserve asset.
/// @param token Address of the token transferred.
error UnauthorizedTransferOut(IERC20Upgradeable token);

/// @notice Expected deposited tranche to be of current deposit bond.
/// @param trancheIn Address of the deposit tranche.
/// @param depositBond Address of the currently accepted deposit bond.
error UnacceptableDepositTranche(ITranche trancheIn, IBondController depositBond);

/// @notice Expected to mint a non-zero amount of tokens.
/// @param trancheInAmt The amount of tranche tokens deposited.
/// @param mintAmt The amount of tranche tokens mint.
error UnacceptableMintAmt(uint256 trancheInAmt, uint256 mintAmt);

/// @notice Expected to redeem current redemption tranche.
/// @param trancheOut Address of the withdrawn tranche.
/// @param redemptionTranche Address of the next tranche up for redemption.
error UnacceptableRedemptionTranche(ITranche trancheOut, ITranche redemptionTranche);

/// @notice Expected to burn a non-zero amount of tokens.
/// @param requestedBurnAmt The amount of tranche tokens requested to be burnt.
/// @param perpSupply The current supply of perp tokens.
error UnacceptableBurnAmt(uint256 requestedBurnAmt, uint256 perpSupply);

/// @notice Expected rollover to be acceptable.
/// @param trancheIn Address of the tranche token transferred in.
/// @param tokenOut Address of the reserve token transferred out.
error UnacceptableRollover(ITranche trancheIn, IERC20Upgradeable tokenOut);

/// @notice Expected to rollover a non-zero amount of tokens.
/// @param trancheInAmt The amount of tranche tokens deposited.
/// @param trancheOutAmt The amount of tranche tokens withdrawn.
/// @param rolloverAmt The perp denominated value of tokens rolled over.
error UnacceptableRolloverAmt(uint256 trancheInAmt, uint256 trancheOutAmt, uint256 rolloverAmt);

/// @notice Expected supply to be lower than the defined max supply.
/// @param newSupply The new total supply after minting.
/// @param currentMaxSupply The current max supply.
error ExceededMaxSupply(uint256 newSupply, uint256 currentMaxSupply);

/// @notice Expected the total mint amount per tranche to be lower than the limit.
/// @param trancheIn Address of the deposit tranche.
/// @param mintAmtForCurrentTranche The amount of perps that have been minted using the tranche.
/// @param maxMintAmtPerTranche The amount of perps that can be minted per tranche.
error ExceededMaxMintPerTranche(ITranche trancheIn, uint256 mintAmtForCurrentTranche, uint256 maxMintAmtPerTranche);

/// @notice Expected the system to have no tranches and have a collateral balance.
error InvalidRebootState();

/*
 *  @title PerpetualTranche
 *
 *  @notice An opinionated implementation of a perpetual note ERC-20 token contract, backed by buttonwood tranches.
 *
 *          Perpetual note tokens (or perps for short) are backed by tokens held in this contract's reserve.
 *          Users can mint perps by depositing tranche tokens into the reserve.
 *          They can redeem tokens from the reserve by burning their perps.
 *
 *          The whitelisted bond issuer issues new deposit bonds periodically based on a predefined frequency.
 *          Users can ONLY mint perps for tranche tokens belonging to the active "deposit" bond.
 *          Users can burn perps, and redeem a proportional share of tokens held in the reserve.
 *
 *          Once tranche tokens held in the reserve mature the underlying collateral is extracted
 *          into the reserve. The system keeps track of total mature tranches held by the reserve.
 *          This acts as an "implied" tranche balance for all collateral extracted from the mature tranches.
 *
 *          At any time, the reserve holds at most 2 classes of tokens
 *          ie) the tranche tokens and mature collateral.
 *
 *          Incentivized parties can "rollover" tranches approaching maturity or the mature collateral,
 *          for newer tranche tokens that belong to the current "depositBond".
 *
 *          The time dependent system state is updated "lazily" without a need for an explicit poke
 *          from the outside world. Every external function that deals with the reserve
 *          invokes the `afterStateUpdate` modifier at the entry-point.
 *          This brings the system storage state up to date.
 *
 */
contract PerpetualTranche is ERC20Upgradeable, OwnableUpgradeable, IPerpetualTranche {
    // math
    using MathUpgradeable for uint256;
    using SafeCastUpgradeable for uint256;
    using SignedMathUpgradeable for int256;

    // data handling
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using BondHelpers for IBondController;
    using TrancheDataHelpers for TrancheData;

    // ERC20 operations
    using SafeERC20Upgradeable for IERC20Upgradeable;

    //-------------------------------------------------------------------------
    // Perp Math Basics:
    //
    // System holds tokens in the reserve {t1, t2 ... tn}
    // with balances {b1, b2 ... bn}.
    //
    // Internally reserve token denominations (amounts/balances) are
    // standardized using a yield factor.
    // Standard denomination: b'i = bi . yield(ti)
    //
    // Yield are typically expected to be ~1.0 for safe tranches,
    // but could be less for riskier junior tranches.
    //
    //
    // System reserve value:
    // RV => t'1 . price(t1) + t'2 . price(t2) + .... + t'n . price(tn)
    //    => Σ t'i . price(ti)
    //
    //
    // When `ai` tokens of type `ti` are deposited into the system:
    // Mint: mintAmt (perps) => (a'i * price(ti) / RV) * supply(perps)
    //
    // This ensures that if 10% of the collateral value is deposited,
    // the minter receives 10% of the perp token supply.
    // This removes any race conditions for minters based on reserve state.
    //
    //
    // When `p` perp tokens are redeemed:
    // Redeem: ForEach ti => (p / supply(perps)) * bi
    //
    //
    // When `ai` tokens of type `ti` are rotated in for tokens of type `tj`:
    // Rotation: aj => ai * yield(ti) / yield(tj), ie) (a'i = a'j)
    //
    //
    //-------------------------------------------------------------------------
    // Constants & Immutables
    uint8 public constant YIELD_DECIMALS = 18;
    uint256 public constant UNIT_YIELD = (10**YIELD_DECIMALS);

    uint8 public constant PRICE_DECIMALS = 8;
    uint256 public constant UNIT_PRICE = (10**PRICE_DECIMALS);

    uint8 public constant PERC_DECIMALS = 6;
    uint256 public constant UNIT_PERC = (10**PERC_DECIMALS);
    uint256 public constant HUNDRED_PERC = 100 * UNIT_PERC;

    //-------------------------------------------------------------------------
    // Storage

    //--------------------------------------------------------------------------
    // CONFIG

    // @notice External contract points to the fee token and computes mint, burn and rollover fees.
    IFeeStrategy public override feeStrategy;

    // @notice External contract that computes a given reserve token's price.
    // @dev The computed price is expected to be a fixed point unsigned integer with {PRICE_DECIMALS} decimals.
    IPricingStrategy public pricingStrategy;

    // @notice External contract that computes a given reserve token's yield.
    // @dev Yield is the discount or premium factor applied to every asset when added to
    //      the reserve. This accounts for things like tranche seniority and underlying
    //      collateral volatility. It also allows for standardizing denominations when comparing,
    //      two different reserve tokens.
    //      The computed yield is expected to be a fixed point unsigned integer with {YIELD_DECIMALS} decimals.
    IYieldStrategy public yieldStrategy;

    // @notice External contract that stores a predefined bond config and frequency,
    //         and issues new bonds when poked.
    // @dev Only tranches of bonds issued by this whitelisted issuer are accepted into the reserve.
    IBondIssuer public bondIssuer;

    // @notice The active deposit bond of whose tranches are currently being accepted to mint perps.
    IBondController private _depositBond;

    // @notice The minimum maturity time in seconds for a tranche below which
    //         it can be rolled over.
    uint256 public minTrancheMaturiySec;

    // @notice The maximum maturity time in seconds for a tranche above which
    //         it can NOT get added into the reserve.
    uint256 public maxTrancheMaturiySec;

    // @notice The maximum supply of perps that can exist at any given time.
    uint256 public maxSupply;

    // @notice The max number of perps that can be minted for each tranche in the minting bond.
    uint256 public maxMintAmtPerTranche;

    // @notice The percentage of the excess value the system retains on rotation.
    // @dev Skim percentage is stored as fixed point number with {PERC_DECIMALS}.
    uint256 public skimPerc;

    // @notice The total number of perps that have been minted using a given tranche.
    mapping(ITranche => uint256) private _mintedSupplyPerTranche;

    // @notice Yield factor actually "applied" on each reserve token. It is computed and recorded when
    //         a token is deposited into the system for the first time.
    // @dev For all calculations thereafter, the token's applied yield will be used.
    //      The yield is stored as a fixed point unsigned integer with {YIELD_DECIMALS} decimals.
    mapping(IERC20Upgradeable => uint256) private _appliedYields;

    //--------------------------------------------------------------------------
    // RESERVE

    // @notice Address of the "underlying" collateral token backing the tranches.
    // @dev ONLY tranches backed by this collateral token can be deposited into the reserve.
    //      Tranches which are not rotated out before maturity, are redeemed and this
    //      collateral is held in the reserve till its rotated out for tranches.
    //      The collateral token is expected to be a rebasing ERC-20.
    IERC20Upgradeable public override collateral;

    // @notice A record of all tranche tokens in the reserve which back the perps.
    EnumerableSetUpgradeable.AddressSet private _reserveTranches;

    // @notice The standardized amount of all tranches deposited into the system.
    uint256 private _stdTotalTrancheBalance;

    // @notice The standardized amount of all the mature tranches extracted and
    //         held as the collateral token.
    uint256 private _stdMatureTrancheBalance;

    //--------------------------------------------------------------------------
    // Modifiers
    modifier afterStateUpdate() {
        updateState();
        _;
    }

    //--------------------------------------------------------------------------
    // Construction & Initialization

    // @notice Contract state initialization.
    // @param name ERC-20 Name of the Perp token.
    // @param symbol ERC-20 Symbol of the Perp token.
    // @param collateral_ Address of the underlying collateral token.
    // @param bondIssuer_ Address of the bond issuer contract.
    // @param feeStrategy_ Address of the fee strategy contract.
    // @param pricingStrategy_ Address of the pricing strategy contract.
    // @param yieldStrategy_ Address of the yield strategy contract.
    function init(
        string memory name,
        string memory symbol,
        IERC20Upgradeable collateral_,
        IBondIssuer bondIssuer_,
        IFeeStrategy feeStrategy_,
        IPricingStrategy pricingStrategy_,
        IYieldStrategy yieldStrategy_
    ) public initializer {
        __ERC20_init(name, symbol);
        __Ownable_init();

        collateral = collateral_;
        _applyYield(collateral_, UNIT_YIELD);

        updateBondIssuer(bondIssuer_);
        updateFeeStrategy(feeStrategy_);
        updatePricingStrategy(pricingStrategy_);
        updateYieldStrategy(yieldStrategy_);

        minTrancheMaturiySec = 1;
        maxTrancheMaturiySec = type(uint256).max;

        maxSupply = 1000000 * (10**decimals()); // 1M
        maxMintAmtPerTranche = 200000 * (10**decimals()); // 200k
    }

    //--------------------------------------------------------------------------
    // ADMIN only methods

    // @notice Update the reference to the bond issuer contract.
    // @param bondIssuer_ New bond issuer address.
    function updateBondIssuer(IBondIssuer bondIssuer_) public onlyOwner {
        if (address(bondIssuer_) == address(0)) {
            revert UnacceptableBondIssuer();
        }
        bondIssuer = bondIssuer_;
        emit UpdatedBondIssuer(bondIssuer_);
    }

    // @notice Update the reference to the fee strategy contract.
    // @param feeStrategy_ New strategy address.
    function updateFeeStrategy(IFeeStrategy feeStrategy_) public onlyOwner {
        if (address(feeStrategy_) == address(0)) {
            revert UnacceptableFeeStrategy();
        }
        feeStrategy = feeStrategy_;
        emit UpdatedFeeStrategy(feeStrategy_);
    }

    // @notice Update the reference to the pricing strategy contract.
    // @param pricingStrategy_ New strategy address.
    function updatePricingStrategy(IPricingStrategy pricingStrategy_) public onlyOwner {
        if (address(pricingStrategy_) == address(0)) {
            revert UnacceptablePricingStrategy();
        }
        if (pricingStrategy_.decimals() != PRICE_DECIMALS) {
            revert InvalidPricingStrategyDecimals();
        }
        pricingStrategy = pricingStrategy_;
        emit UpdatedPricingStrategy(pricingStrategy_);
    }

    // @notice Update the reference to the yield strategy contract.
    // @param yieldStrategy_ New strategy address.
    function updateYieldStrategy(IYieldStrategy yieldStrategy_) public onlyOwner {
        if (address(yieldStrategy_) == address(0)) {
            revert UnacceptableYieldStrategy();
        }
        if (yieldStrategy_.decimals() != YIELD_DECIMALS) {
            revert InvalidYieldStrategyDecimals();
        }
        yieldStrategy = yieldStrategy_;
        emit UpdatedYieldStrategy(yieldStrategy_);
    }

    // @notice Update the maturity tolerance parameters.
    // @param minTrancheMaturiySec_ New minimum maturity time.
    // @param maxTrancheMaturiySec_ New maximum maturity time.
    function updateTolerableTrancheMaturiy(uint256 minTrancheMaturiySec_, uint256 maxTrancheMaturiySec_)
        external
        onlyOwner
    {
        if (minTrancheMaturiySec_ > maxTrancheMaturiySec_) {
            revert InvalidTrancheMaturityBounds(minTrancheMaturiySec_, maxTrancheMaturiySec_);
        }
        minTrancheMaturiySec = minTrancheMaturiySec_;
        maxTrancheMaturiySec = maxTrancheMaturiySec_;
        emit UpdatedTolerableTrancheMaturiy(minTrancheMaturiySec_, maxTrancheMaturiySec_);
    }

    // @notice Update parameters controlling the perp token mint limits.
    // @param maxSupply_ New max total supply.
    // @param maxMintAmtPerTranche_ New max total for per tranche in minting bond.
    function updateMintingLimits(uint256 maxSupply_, uint256 maxMintAmtPerTranche_) external onlyOwner {
        maxSupply = maxSupply_;
        maxMintAmtPerTranche = maxMintAmtPerTranche_;
        emit UpdatedMintingLimits(maxSupply_, maxMintAmtPerTranche_);
    }

    // @notice Updates the skim percentage parameter.
    // @param skimPerc_ New skim percentage.
    function updateSkimPerc(uint256 skimPerc_) external onlyOwner {
        if (skimPerc_ > HUNDRED_PERC) {
            revert UnacceptableSkimPerc(skimPerc_);
        }
        skimPerc = skimPerc_;
        emit UpdatedSkimPerc(skimPerc_);
    }

    // @notice Allows the owner to transfer non-reserve assets out of the system if required.
    // @param token The token address.
    // @param to The destination address.
    // @param amount The amount of tokens to be transferred.
    function transferERC20(
        IERC20Upgradeable token,
        address to,
        uint256 amount
    ) external afterStateUpdate onlyOwner {
        if (_isReserveToken(token)) {
            revert UnauthorizedTransferOut(token);
        }
        token.safeTransfer(to, amount);
    }

    // @notice Redenominates Perp with respect to the outstanding debt.
    // @param stdTrancheBalance The new tranche balance of matured collateral.
    // @dev Can only be used is perp is backed solely by matured collateral.
    function redenominate(uint256 stdTrancheBalance) external afterStateUpdate onlyOwner {
        // The redenomination is only allowed when:
        //  - the system has no more tranches left i.e) all the tranches have mature
        //  - the system has a collateral balance
        if (_reserveCount() > 1 || _tokenBalance(collateral) == 0) {
            revert InvalidRebootState();
        }
        _updateStdTotalTrancheBalance(stdTrancheBalance);
        _updateStdMatureTrancheBalance(stdTrancheBalance);
    }

    //--------------------------------------------------------------------------
    // External methods

    /// @inheritdoc IPerpetualTranche
    function deposit(ITranche trancheIn, uint256 trancheInAmt) external override afterStateUpdate {
        if (IBondController(trancheIn.bond()) != _depositBond) {
            revert UnacceptableDepositTranche(trancheIn, _depositBond);
        }

        // calculates the amount of perp tokens when depositing `trancheInAmt` of tranche tokens
        (uint256 mintAmt, uint256 stdTrancheInAmt) = _computeMintAmt(trancheIn, trancheInAmt);
        if (trancheInAmt == 0 || mintAmt == 0) {
            revert UnacceptableMintAmt(stdTrancheInAmt, mintAmt);
        }

        // calculates the fee to mint `mintAmt` of perp token
        int256 mintFee = feeStrategy.computeMintFee(mintAmt);

        // transfers tranche tokens from the sender to the reserve
        _transferIntoReserve(_msgSender(), trancheIn, trancheInAmt);

        // mints perp tokens to the sender
        _mint(_msgSender(), mintAmt);

        // settles fees
        _settleFee(_msgSender(), mintFee);

        // updates reserve's tranche balance
        _updateStdTotalTrancheBalance(_stdTotalTrancheBalance + stdTrancheInAmt);

        // updates & enforces supply cap and tranche mint cap
        _mintedSupplyPerTranche[trancheIn] += mintAmt;
        _enforceMintingLimits(trancheIn);
    }

    /// @inheritdoc IPerpetualTranche
    function burn(uint256 perpAmtBurnt) external override afterStateUpdate {
        // gets the current perp supply
        uint256 perpSupply = totalSupply();

        // verifies if burn amount is acceptable
        if (perpAmtBurnt == 0 || perpAmtBurnt > perpSupply) {
            revert UnacceptableBurnAmt(perpAmtBurnt, perpSupply);
        }

        // calculates share of reserve tokens to be redeemed
        (IERC20Upgradeable[] memory tokensOuts, uint256[] memory tokenOutAmts) = _computeRedemptionAmts(perpAmtBurnt);

        // calculates the fee to burn `perpAmtBurnt` of perp token
        int256 burnFee = feeStrategy.computeBurnFee(perpAmtBurnt);

        // updates reserve's tranche balances
        _updateStdTotalTrancheBalance((_stdTotalTrancheBalance * (perpSupply - perpAmtBurnt)) / perpSupply);
        _updateStdMatureTrancheBalance((_stdMatureTrancheBalance * (perpSupply - perpAmtBurnt)) / perpSupply);

        // settles fees
        _settleFee(_msgSender(), burnFee);

        // burns perp tokens from the sender
        _burn(_msgSender(), perpAmtBurnt);

        // transfers reserve tokens out
        for (uint256 i = 0; i < tokensOuts.length; i++) {
            if (tokenOutAmts[i] > 0) {
                _transferOutOfReserve(_msgSender(), tokensOuts[i], tokenOutAmts[i]);
            }
        }
    }

    /// @inheritdoc IPerpetualTranche
    function rollover(
        ITranche trancheIn,
        IERC20Upgradeable tokenOut,
        uint256 trancheInAmtRequested
    ) external override afterStateUpdate {
        if (!_isAcceptableRollover(trancheIn, tokenOut)) {
            revert UnacceptableRollover(trancheIn, tokenOut);
        }

        // calculates the perp denominated amount rolled over and the tokenOutAmt
        IPerpetualTranche.RolloverPreview memory r = _computeRolloverAmt(
            trancheIn,
            tokenOut,
            trancheInAmtRequested,
            type(uint256).max
        );

        // verifies if rollover amount is acceptable
        if (r.trancheInAmtUsed == 0 || r.tokenOutAmt == 0 || r.perpRolloverAmt == 0) {
            revert UnacceptableRolloverAmt(r.trancheInAmtUsed, r.tokenOutAmt, r.perpRolloverAmt);
        }

        // calculates the fee to rollover `r.perpRolloverAmt` of perp token
        int256 rolloverFee = feeStrategy.computeRolloverFee(r.perpRolloverAmt);

        // transfers tranche tokens from the sender to the reserve
        _transferIntoReserve(_msgSender(), trancheIn, r.trancheInAmtUsed);

        // settles fees
        _settleFee(_msgSender(), rolloverFee);

        // updates mature tranche balance
        // NOTE: total tranche balance does not change on rollovers
        //        as `stdTrancheInAmt` == `stdTrancheOutAmt`
        if (tokenOut == collateral) {
            _updateStdMatureTrancheBalance(_stdMatureTrancheBalance - r.stdTrancheRolloverAmt);
        }

        // transfers tranche from the reserve to the sender
        _transferOutOfReserve(_msgSender(), tokenOut, r.tokenOutAmt);
    }

    /// @inheritdoc IPerpetualTranche
    // @dev Used in case an altruistic party intends to increase the collaterlization ratio.
    function burnWithoutRedemption(uint256 amount) external override returns (bool) {
        _burn(_msgSender(), amount);
        return true;
    }

    /// @inheritdoc IPerpetualTranche
    function getStdTrancheBalances() external override afterStateUpdate returns (uint256, uint256) {
        return (_stdTotalTrancheBalance, _stdMatureTrancheBalance);
    }

    /// @inheritdoc IPerpetualTranche
    function getDepositBond() external override afterStateUpdate returns (IBondController) {
        return _depositBond;
    }

    /// @inheritdoc IPerpetualTranche
    function isAcceptableRollover(ITranche trancheIn, IERC20Upgradeable tokenOut)
        external
        override
        afterStateUpdate
        returns (bool)
    {
        return _isAcceptableRollover(trancheIn, tokenOut);
    }

    /// @inheritdoc IPerpetualTranche
    function getReserveCount() external override afterStateUpdate returns (uint256) {
        return _reserveCount();
    }

    /// @inheritdoc IPerpetualTranche
    function getReserveAt(uint256 i) external override afterStateUpdate returns (IERC20Upgradeable) {
        return _reserveAt(i);
    }

    /// @inheritdoc IPerpetualTranche
    function getReserveBalance(IERC20Upgradeable token) external override afterStateUpdate returns (uint256) {
        return _isReserveToken(token) ? _tokenBalance(token) : 0;
    }

    /// @inheritdoc IPerpetualTranche
    function isReserveToken(IERC20Upgradeable token) external override afterStateUpdate returns (bool) {
        return _isReserveToken(token);
    }

    /// @inheritdoc IPerpetualTranche
    function isReserveTranche(IERC20Upgradeable tranche) external override afterStateUpdate returns (bool) {
        return _isReserveTranche(tranche);
    }

    /// @inheritdoc IPerpetualTranche
    // @dev Reserve tokens which are not up for rollover are marked by `address(0)`.
    function getReserveTokensUpForRollover() external override afterStateUpdate returns (IERC20Upgradeable[] memory) {
        uint256 reserveCount = _reserveCount();
        IERC20Upgradeable[] memory rolloverTokens = new IERC20Upgradeable[](reserveCount);
        for (uint256 i = 0; i < reserveCount; i++) {
            IERC20Upgradeable token = _reserveAt(i);
            if (i == 0 || !_isAcceptableForReserve(IBondController(ITranche(address(token)).bond()))) {
                rolloverTokens[i] = token;
            }
        }
        return rolloverTokens;
    }

    /// @inheritdoc IPerpetualTranche
    // @dev Returns a fixed point with {PRICE_DECIMALS} decimals.
    function getReserveValue() external override afterStateUpdate returns (uint256) {
        return _reserveValue();
    }

    /// @inheritdoc IPerpetualTranche
    function computeMintAmt(ITranche trancheIn, uint256 trancheInAmt)
        external
        override
        afterStateUpdate
        returns (uint256, uint256)
    {
        return _computeMintAmt(trancheIn, trancheInAmt);
    }

    /// @inheritdoc IPerpetualTranche
    function computeRedemptionAmts(uint256 perpAmtBurnt)
        external
        override
        afterStateUpdate
        returns (IERC20Upgradeable[] memory, uint256[] memory)
    {
        return _computeRedemptionAmts(perpAmtBurnt);
    }

    /// @inheritdoc IPerpetualTranche
    // @dev Set `maxTokenOutAmtCovered` to max(uint256) to use the reserve balance.
    function computeRolloverAmt(
        ITranche trancheIn,
        IERC20Upgradeable tokenOut,
        uint256 trancheInAmtRequested,
        uint256 maxTokenOutAmtCovered
    ) external override afterStateUpdate returns (IPerpetualTranche.RolloverPreview memory) {
        return _computeRolloverAmt(trancheIn, tokenOut, trancheInAmtRequested, maxTokenOutAmtCovered);
    }

    //--------------------------------------------------------------------------
    // Public methods

    /// @inheritdoc IPerpetualTranche
    // @dev Lazily updates time-dependent reserve storage state.
    //      This function is to be invoked on all external function entry points which are
    //      read the reserve storage. This function is intended to be idempotent.
    function updateState() public override {
        // Lazily queries the bond issuer to get the most recently issued bond
        // and updates with the new deposit bond if it's "acceptable".
        IBondController newBond = bondIssuer.getLatestBond();

        // If the new bond has been issued by the issuer and is "acceptable"
        if (_depositBond != newBond && _isAcceptableForReserve(newBond)) {
            // updates `_depositBond` with the new bond
            _depositBond = newBond;
            emit UpdatedDepositBond(newBond);
        }

        // Lazily checks if every reserve tranche has reached maturity.
        // If so redeems the tranche balance for the underlying collateral and
        // removes the tranche from the reserve list.
        // NOTE: We traverse the reserve list in the reverse order
        //       as deletions involve swapping the deleted element to the
        //       end of the list and removing the last element.
        //       We also skip the `reserveAt(0)`, ie the mature tranche,
        //       which is never removed.
        uint256 reserveCount = _reserveCount();
        for (uint256 i = reserveCount - 1; i > 0; i--) {
            ITranche tranche = ITranche(address(_reserveAt(i)));
            IBondController bond = IBondController(tranche.bond());

            // If bond is not mature yet, move to the next tranche
            if (bond.timeToMaturity() > 0) {
                continue;
            }

            // If bond has reached maturity but hasn't been poked
            if (!bond.isMature()) {
                bond.mature();
            }

            // Redeeming collateral
            uint256 trancheBalance = _tokenBalance(tranche);
            bond.redeemMature(address(tranche), trancheBalance);
            _syncReserve(tranche);

            // Keeps track of the total tranches redeemed
            _updateStdMatureTrancheBalance(
                _stdMatureTrancheBalance + _toStdTrancheAmt(trancheBalance, computeYield(tranche))
            );
        }

        // Keeps track of reserve's rebasing collateral token balance
        _syncReserve(collateral);
    }

    //--------------------------------------------------------------------------
    // External view methods

    /// @inheritdoc IPerpetualTranche
    function reserve() external view override returns (address) {
        return _self();
    }

    /// @inheritdoc IPerpetualTranche
    function feeCollector() external view override returns (address) {
        return _self();
    }

    //--------------------------------------------------------------------------
    // Public view methods

    /// @inheritdoc IPerpetualTranche
    function feeToken() public view override returns (IERC20Upgradeable) {
        return feeStrategy.feeToken();
    }

    /// @inheritdoc IPerpetualTranche
    // @dev Gets the applied yield for the given tranche if it's set,
    //      if NOT computes the yield.
    function computeYield(IERC20Upgradeable token) public view override returns (uint256) {
        uint256 yield = _appliedYields[token];
        return (yield > 0) ? yield : yieldStrategy.computeYield(token);
    }

    /// @inheritdoc IPerpetualTranche
    function computePrice(IERC20Upgradeable token) public view override returns (uint256) {
        return
            (token == collateral)
                ? pricingStrategy.computeMatureTranchePrice(token, _tokenBalance(token), _matureTrancheBalance())
                : pricingStrategy.computeTranchePrice(ITranche(address(token)));
    }

    // @notice Returns the number of decimals used to get its user representation.
    // @dev For example, if `decimals` equals `2`, a balance of `505` tokens should
    //      be displayed to a user as `5.05` (`505 / 10 ** 2`).
    function decimals() public view override returns (uint8) {
        return IERC20MetadataUpgradeable(address(collateral)).decimals();
    }

    //--------------------------------------------------------------------------
    // Private/Internal helper methods

    // @dev Computes the perp mint amount for given amount of tranche tokens deposited into the reserve.
    function _computeMintAmt(ITranche trancheIn, uint256 trancheInAmt) private view returns (uint256, uint256) {
        uint256 totalSupply_ = totalSupply();
        uint256 stdTrancheInAmt = _toStdTrancheAmt(trancheInAmt, computeYield(trancheIn));
        uint256 trancheInPrice = computePrice(trancheIn);
        uint256 mintAmt = (totalSupply_ > 0)
            ? (stdTrancheInAmt * trancheInPrice * totalSupply_) / _reserveValue()
            : (stdTrancheInAmt * trancheInPrice) / UNIT_PRICE;
        return (mintAmt, stdTrancheInAmt);
    }

    // @dev Computes the reserve token amounts redeemed when a given number of perps are burnt.
    function _computeRedemptionAmts(uint256 perpAmtBurnt)
        private
        view
        returns (IERC20Upgradeable[] memory, uint256[] memory)
    {
        uint256 totalSupply_ = totalSupply();
        uint256 reserveCount = _reserveCount();
        IERC20Upgradeable[] memory reserveTokens = new IERC20Upgradeable[](reserveCount);
        uint256[] memory redemptionAmts = new uint256[](reserveCount);
        for (uint256 i = 0; i < reserveCount; i++) {
            reserveTokens[i] = _reserveAt(i);
            redemptionAmts[i] = (_tokenBalance(reserveTokens[i]) * perpAmtBurnt) / totalSupply_;
        }
        return (reserveTokens, redemptionAmts);
    }

    // @dev Computes the amount of reserve tokens that can be rolled out for the given amount of tranches deposited.
    function _computeRolloverAmt(
        ITranche trancheIn,
        IERC20Upgradeable tokenOut,
        uint256 trancheInAmtRequested,
        uint256 maxTokenOutAmtCovered
    ) private view returns (IPerpetualTranche.RolloverPreview memory) {
        IPerpetualTranche.RolloverPreview memory r;

        uint256 trancheInYield = computeYield(trancheIn);
        uint256 trancheOutYield = computeYield(tokenOut);
        uint256 trancheInPrice = computePrice(trancheIn);
        uint256 trancheOutPrice = computePrice(tokenOut);
        if (trancheInYield == 0 || trancheOutYield == 0 || trancheInPrice == 0 || trancheOutPrice == 0) {
            r.remainingTrancheInAmt = trancheInAmtRequested;
            return r;
        }

        uint256 tokenOutBalance = _tokenBalance(tokenOut);
        maxTokenOutAmtCovered = MathUpgradeable.min(maxTokenOutAmtCovered, tokenOutBalance);

        r.trancheInAmtUsed = trancheInAmtRequested;
        r.stdTrancheRolloverAmt = _toStdTrancheAmt(trancheInAmtRequested, trancheInYield);

        // Rollovers are denominated in tranche amounts.
        // ie) 1 "standardized" trancheIn tokens are rolled over for 1 "standardized" tokenOut tokens.
        //
        // However, if the tokenOut is the mature tranche (held as naked collateral),
        // we infer the tokenOut amount from the tranche denomination.
        // (tokenOutAmt = trancheOutAmt * collateralBalance / matureTrancheBalance)

        uint256 matureTrancheBalance = _matureTrancheBalance();
        bool isTokenOutCollateral = tokenOut == collateral;

        // Basic rollover:
        // (trancheInAmtRequested . trancheInYield) = (trancheOutAmt. trancheOutYield)
        uint256 trancheOutAmt = _fromStdTrancheAmt(r.stdTrancheRolloverAmt, trancheOutYield);
        r.tokenOutAmt = isTokenOutCollateral
            ? ((tokenOutBalance * trancheOutAmt) / matureTrancheBalance)
            : trancheOutAmt;

        // When the token out balance is NOT covered:
        // we fix tokenOutAmt = maxTokenOutAmtCovered and back calculate other values
        if (r.tokenOutAmt > maxTokenOutAmtCovered) {
            r.tokenOutAmt = maxTokenOutAmtCovered;
            trancheOutAmt = isTokenOutCollateral
                ? (matureTrancheBalance * r.tokenOutAmt) / tokenOutBalance
                : r.tokenOutAmt;
            r.stdTrancheRolloverAmt = _toStdTrancheAmt(trancheOutAmt, trancheOutYield);
            r.trancheInAmtUsed = _fromStdTrancheAmt(r.stdTrancheRolloverAmt, trancheInYield);
        }

        // When skimming:
        // value(tranche) = (trancheAmt * trancheYield) * tranchePrice
        //
        // When the rollover is measured as extractive (i.e valueOut > valueIn),
        // the system skims a portion of the excess value.
        //
        // valueIn = (trancheInYield * r.trancheInAmtUsed) * trancheInPrice
        // valueOut = (trancheOutYield * trancheOutAmt) * trancheOutPrice
        // w.k.t (trancheInYield * r.trancheInAmtUsed) = (trancheOutYield * trancheOutAmt) = r.stdTrancheRolloverAmt
        // Thus, valueOut/valueIn => trancheOutPrice/trancheInPrice
        if (skimPerc > 0 && (trancheOutPrice > trancheInPrice)) {
            // We calculate the adjusted `tokenOutAmt` after skimming and
            // back calculate the `stdTrancheRolloverAmt`
            uint256 adjustedTrancheOutPrice = trancheOutPrice -
                ((skimPerc * (trancheOutPrice - trancheInPrice)) / HUNDRED_PERC);
            r.tokenOutAmt = (r.tokenOutAmt * adjustedTrancheOutPrice) / trancheOutPrice;
            trancheOutAmt = isTokenOutCollateral
                ? (matureTrancheBalance * r.tokenOutAmt) / tokenOutBalance
                : r.tokenOutAmt;
            r.stdTrancheRolloverAmt = _toStdTrancheAmt(trancheOutAmt, trancheOutYield);
        }

        r.perpRolloverAmt = (totalSupply() * r.stdTrancheRolloverAmt) / _stdTotalTrancheBalance;
        r.remainingTrancheInAmt = trancheInAmtRequested - r.trancheInAmtUsed;
        return r;
    }

    // @dev Transfers tokens from the given address to self and updates the reserve list.
    // @return Reserve's token balance after transfer in.
    function _transferIntoReserve(
        address from,
        IERC20Upgradeable token,
        uint256 trancheAmt
    ) internal returns (uint256) {
        token.safeTransferFrom(from, _self(), trancheAmt);
        return _syncReserve(token);
    }

    // @dev Transfers tokens from self into the given address and updates the reserve list.
    // @return Reserve's token balance after transfer out.
    function _transferOutOfReserve(
        address to,
        IERC20Upgradeable token,
        uint256 tokenAmt
    ) internal returns (uint256) {
        token.safeTransfer(to, tokenAmt);
        return _syncReserve(token);
    }

    // @dev Keeps the reserve storage up to date. Logs the token balance held by the reserve.
    // @return The Reserve's token balance.
    function _syncReserve(IERC20Upgradeable token) internal returns (uint256) {
        uint256 balance = _tokenBalance(token);
        emit ReserveSynced(token, balance);

        // If token is a tranche
        if (token != collateral) {
            bool isReserveTranche_ = _isReserveTranche(token);
            if (balance > 0 && !isReserveTranche_) {
                // Inserts new tranche into reserve list.
                _reserveTranches.add(address(token));

                // Stores the yield for future usage.
                _applyYield(token, computeYield(token));
            }

            if (balance == 0 && isReserveTranche_) {
                // Removes tranche from reserve list.
                _reserveTranches.remove(address(token));

                // Frees up stored yield.
                _applyYield(token, 0);

                // Frees up minted supply.
                delete _mintedSupplyPerTranche[ITranche(address(token))];
            }
        }

        return balance;
    }

    // @dev If the fee is positive, fee is transferred from the payer to the self
    //      else it's transferred to the payer from the self.
    //      NOTE: fee is a not-reserve asset.
    // @return True if the fee token used for settlement is the perp token.
    function _settleFee(address payer, int256 fee) internal returns (bool isNativeFeeToken) {
        IERC20Upgradeable feeToken_ = feeToken();
        isNativeFeeToken = (address(feeToken_) == _self());

        if (fee == 0) {
            return isNativeFeeToken;
        }

        uint256 fee_ = fee.abs();
        if (fee > 0) {
            // Funds are coming in
            // Handling a special case, when the fee is to be charged as the perp token itself
            // In this case we don't need to make an external call to the token ERC-20 to "transferFrom"
            // the payer, since this is still an internal call {msg.sender} will still point to the payer
            // and we can just "transfer" from the payer's wallet.
            if (isNativeFeeToken) {
                transfer(_self(), fee_);
            } else {
                feeToken_.safeTransferFrom(payer, _self(), fee_);
            }
        } else {
            // Funds are going out
            feeToken_.safeTransfer(payer, fee_);
        }

        return isNativeFeeToken;
    }

    // @dev Updates contract store with provided yield.
    function _applyYield(IERC20Upgradeable token, uint256 yield) private {
        if (yield > 0) {
            _appliedYields[token] = yield;
        } else {
            delete _appliedYields[token];
        }
        emit YieldApplied(token, yield);
    }

    // @dev Updates the standardized total tranche balance in storage.
    function _updateStdTotalTrancheBalance(uint256 stdTotalTrancheBalance) private {
        _stdTotalTrancheBalance = stdTotalTrancheBalance;
        emit UpdatedStdTotalTrancheBalance(stdTotalTrancheBalance);
    }

    // @dev Updates the standardized mature tranche balance in storage.
    function _updateStdMatureTrancheBalance(uint256 stdMatureTrancheBalance) private {
        _stdMatureTrancheBalance = stdMatureTrancheBalance;
        emit UpdatedStdMatureTrancheBalance(stdMatureTrancheBalance);
    }

    // @dev Checks if the given token pair is a valid rollover.
    //      * When rolling out mature collateral,
    //          - expects incoming tranche to be part of the deposit bond
    //      * When rolling out immature tranches,
    //          - expects incoming tranche to be part of the deposit bond
    //          - expects outgoing tranche to not be part of the deposit bond
    //          - expects outgoing tranche to be in the reserve
    //          - expects outgoing bond to not be "acceptable" any more
    function _isAcceptableRollover(ITranche trancheIn, IERC20Upgradeable tokenOut) internal view returns (bool) {
        IBondController bondIn = IBondController(trancheIn.bond());

        // when rolling out the mature collateral
        if (tokenOut == collateral) {
            return (bondIn == _depositBond);
        }

        // when rolling out an immature tranche
        ITranche trancheOut = ITranche(address(tokenOut));
        IBondController bondOut = IBondController(trancheOut.bond());
        return (bondIn == _depositBond &&
            bondOut != _depositBond &&
            _isReserveTranche(trancheOut) &&
            !_isAcceptableForReserve(bondOut));
    }

    // @dev Checks if the bond's tranches can be accepted into the reserve.
    //      * Expects the bond to to have the same collateral token as perp.
    //      * Expects the bond's maturity to be within expected bounds.
    // @return True if the bond is "acceptable".
    function _isAcceptableForReserve(IBondController bond) internal view returns (bool) {
        // NOTE: `timeToMaturity` will be 0 if the bond is past maturity.
        uint256 timeToMaturity = bond.timeToMaturity();
        return (address(collateral) == bond.collateralToken() &&
            timeToMaturity >= minTrancheMaturiySec &&
            timeToMaturity < maxTrancheMaturiySec);
    }

    // @dev Enforces the mint limits. To be invoked AFTER the mint operation.
    function _enforceMintingLimits(ITranche trancheIn) private view {
        // checks if new total supply is within the max supply cap
        uint256 newSupply = totalSupply();
        if (newSupply > maxSupply) {
            revert ExceededMaxSupply(newSupply, maxSupply);
        }

        // checks if supply minted using the given tranche is within the cap
        if (_mintedSupplyPerTranche[trancheIn] > maxMintAmtPerTranche) {
            revert ExceededMaxMintPerTranche(trancheIn, _mintedSupplyPerTranche[trancheIn], maxMintAmtPerTranche);
        }
    }

    // @dev Counts the number of tokens currently in the reserve.
    //      The reserve comprises of the list of tranches and the mature collateral.
    //      The `reserveCount` will always be 1 even if it's empty.
    function _reserveCount() private view returns (uint256) {
        return _reserveTranches.length() + 1;
    }

    // @dev Fetches the reserve token by index.
    //      NOTE: index=0 returns the mature collateral.
    function _reserveAt(uint256 i) private view returns (IERC20Upgradeable) {
        return (i == 0) ? collateral : IERC20Upgradeable(_reserveTranches.at(i - 1));
    }

    // @dev Checks if the given token is in the reserve.
    function _isReserveToken(IERC20Upgradeable token) private view returns (bool) {
        return _isReserveTranche(token) || token == collateral;
    }

    // @dev Checks if the given token is a tranche in the reserve.
    function _isReserveTranche(IERC20Upgradeable tranche) private view returns (bool) {
        return _reserveTranches.contains(address(tranche));
    }

    // @dev Calculates the total value of all the tranches in the reserve.
    //      Value of each reserve tranche is calculated as = (trancheYield . trancheBalance) . tranchePrice.
    function _reserveValue() private view returns (uint256) {
        uint256 totalVal = 0;
        for (uint256 i = 0; i < _reserveCount(); i++) {
            IERC20Upgradeable token = _reserveAt(i);
            uint256 stdTrancheAmt = (i == 0)
                ? _stdMatureTrancheBalance
                : _toStdTrancheAmt(_tokenBalance(token), computeYield(token));
            totalVal += (stdTrancheAmt * computePrice(token));
        }
        return totalVal;
    }

    // @dev Calculates the mature tranche balance.
    function _matureTrancheBalance() private view returns (uint256) {
        return _fromStdTrancheAmt(_stdMatureTrancheBalance, computeYield(collateral));
    }

    // @dev Fetches the perp contract's token balance.
    function _tokenBalance(IERC20Upgradeable token) private view returns (uint256) {
        return token.balanceOf(_self());
    }

    // @dev Alias to self.
    function _self() private view returns (address) {
        return address(this);
    }

    // @dev Calculates the standardized tranche amount for internal book keeping.
    //      stdTrancheAmt = (trancheAmt * yield).
    function _toStdTrancheAmt(uint256 trancheAmt, uint256 yield) private pure returns (uint256) {
        return ((trancheAmt * yield) / UNIT_YIELD);
    }

    // @dev Calculates the external tranche amount from the internal standardized tranche amount.
    //      trancheAmt = stdTrancheAmt / yield.
    function _fromStdTrancheAmt(uint256 stdTrancheAmt, uint256 yield) private pure returns (uint256) {
        return ((stdTrancheAmt * UNIT_YIELD) / yield);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

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
library SafeCastUpgradeable {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
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
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
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
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
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
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
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
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
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
     * - input must fit into 8 bits.
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
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
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
     * - input must fit into 8 bits.
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
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMathUpgradeable {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

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
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
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
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
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
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

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
 */
library EnumerableSetUpgradeable {
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

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

import { SafeCastUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { IBondController } from "../_interfaces/buttonwood/IBondController.sol";
import { ITranche } from "../_interfaces/buttonwood/ITranche.sol";

/// @notice Expected tranche to be part of bond.
/// @param tranche Address of the tranche token.
error UnacceptableTrancheIndex(ITranche tranche);

struct TrancheData {
    ITranche[] tranches;
    uint256[] trancheRatios;
    uint8 trancheCount;
}

/*
 *  @title TrancheDataHelpers
 *
 *  @notice Library with helper functions the bond's retrieved tranche data.
 *
 */
library TrancheDataHelpers {
    // @notice Iterates through the tranche data to find the seniority index of the given tranche.
    // @param td The tranche data object.
    // @param t The address of the tranche to check.
    // @return the index of the tranche in the tranches array.
    function getTrancheIndex(TrancheData memory td, ITranche t) internal pure returns (uint256) {
        for (uint8 i = 0; i < td.trancheCount; i++) {
            if (td.tranches[i] == t) {
                return i;
            }
        }
        revert UnacceptableTrancheIndex(t);
    }
}

/*
 *  @title TrancheHelpers
 *
 *  @notice Library with helper functions tranche tokens.
 *
 */
library TrancheHelpers {
    // @notice Given a tranche, looks up the collateral balance backing the tranche supply.
    // @param t Address of the tranche token.
    // @return The collateral balance and the tranche token supply.
    function getTrancheCollateralization(ITranche t) internal view returns (uint256, uint256) {
        IBondController bond = IBondController(t.bond());
        TrancheData memory td;
        uint256[] memory collateralBalances;
        uint256[] memory trancheSupplies;
        (td, collateralBalances, trancheSupplies) = BondHelpers.getTrancheCollateralizations(bond);
        uint256 trancheIndex = TrancheDataHelpers.getTrancheIndex(td, t);
        return (collateralBalances[trancheIndex], trancheSupplies[trancheIndex]);
    }
}

/*
 *  @title BondHelpers
 *
 *  @notice Library with helper functions for ButtonWood's Bond contract.
 *
 */
library BondHelpers {
    // Replicating value used here:
    // https://github.com/buttonwood-protocol/tranche/blob/main/contracts/BondController.sol
    uint256 private constant TRANCHE_RATIO_GRANULARITY = 1000;
    uint256 private constant BPS = 10_000;

    // @notice Given a bond, calculates the time remaining to maturity.
    // @param b The address of the bond contract.
    // @return The number of seconds before the bond reaches maturity.
    function timeToMaturity(IBondController b) internal view returns (uint256) {
        uint256 maturityDate = b.maturityDate();
        return maturityDate > block.timestamp ? maturityDate - block.timestamp : 0;
    }

    // @notice Given a bond, calculates the bond duration i.e)
    //         difference between creation time and maturity time.
    // @param b The address of the bond contract.
    // @return The duration in seconds.
    function duration(IBondController b) internal view returns (uint256) {
        return b.maturityDate() - b.creationDate();
    }

    // @notice Given a bond, retrieves all of the bond's tranche related data.
    // @param b The address of the bond contract.
    // @return The tranche data.
    function getTrancheData(IBondController b) internal view returns (TrancheData memory) {
        TrancheData memory td;
        td.trancheCount = SafeCastUpgradeable.toUint8(b.trancheCount());
        td.tranches = new ITranche[](td.trancheCount);
        td.trancheRatios = new uint256[](td.trancheCount);
        // Max tranches per bond < 2**8 - 1
        for (uint8 i = 0; i < td.trancheCount; i++) {
            (ITranche t, uint256 ratio) = b.tranches(i);
            td.tranches[i] = t;
            td.trancheRatios[i] = ratio;
        }
        return td;
    }

    // @notice Helper function to estimate the amount of tranches minted when a given amount of collateral
    //         is deposited into the bond.
    // @dev This function is used off-chain services (using callStatic) to preview tranches minted after
    // @param b The address of the bond contract.
    // @return The tranche data, an array of tranche amounts and fees.
    function previewDeposit(IBondController b, uint256 collateralAmount)
        internal
        view
        returns (
            TrancheData memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        TrancheData memory td = getTrancheData(b);
        uint256[] memory trancheAmts = new uint256[](td.trancheCount);
        uint256[] memory fees = new uint256[](td.trancheCount);

        uint256 totalDebt = b.totalDebt();
        uint256 collateralBalance = IERC20Upgradeable(b.collateralToken()).balanceOf(address(b));
        uint256 feeBps = b.feeBps();

        for (uint256 i = 0; i < td.trancheCount; i++) {
            uint256 trancheValue = (collateralAmount * td.trancheRatios[i]) / TRANCHE_RATIO_GRANULARITY;
            if (collateralBalance > 0) {
                trancheValue = (trancheValue * totalDebt) / collateralBalance;
            }
            fees[i] = (trancheValue * feeBps) / BPS;
            if (fees[i] > 0) {
                trancheValue -= fees[i];
            }
            trancheAmts[i] = trancheValue;
        }

        return (td, trancheAmts, fees);
    }

    // @notice Given a bond, for each tranche token retrieves the total collateral redeemable
    //         for the total supply of the tranche token (aka debt issued).
    // @dev The cdr can be computed for each tranche by dividing the
    //      returned tranche's collateralBalance by the tranche's totalSupply.
    // @param b The address of the bond contract.
    // @return The tranche data and the list of collateral balances and the total supplies for each tranche.
    function getTrancheCollateralizations(IBondController b)
        internal
        view
        returns (
            TrancheData memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        TrancheData memory td = getTrancheData(b);
        uint256[] memory collateralBalances = new uint256[](td.trancheCount);
        uint256[] memory trancheSupplies = new uint256[](td.trancheCount);

        // When the bond is mature, the collateral is transferred over to the individual tranche token contracts
        if (b.isMature()) {
            for (uint8 i = 0; i < td.trancheCount; i++) {
                trancheSupplies[i] = td.tranches[i].totalSupply();
                collateralBalances[i] = IERC20Upgradeable(b.collateralToken()).balanceOf(address(td.tranches[i]));
            }
            return (td, collateralBalances, trancheSupplies);
        }

        // Before the bond is mature, all the collateral is held by the bond contract
        uint256 bondCollateralBalance = IERC20Upgradeable(b.collateralToken()).balanceOf(address(b));
        uint256 zTrancheIndex = td.trancheCount - 1;
        for (uint8 i = 0; i < td.trancheCount; i++) {
            trancheSupplies[i] = td.tranches[i].totalSupply();

            // a to y tranches
            if (i != zTrancheIndex) {
                collateralBalances[i] = (trancheSupplies[i] <= bondCollateralBalance)
                    ? trancheSupplies[i]
                    : bondCollateralBalance;
                bondCollateralBalance -= collateralBalances[i];
            }
            // z tranche
            else {
                collateralBalances[i] = bondCollateralBalance;
            }
        }

        return (td, collateralBalances, trancheSupplies);
    }

    // @notice Given a bond, retrieves the collateral redeemable for
    //         each tranche held by the given address.
    // @param b The address of the bond contract.
    // @param u The address to check balance for.
    // @return The tranche data and an array of collateral balances.
    function getTrancheCollateralBalances(IBondController b, address u)
        internal
        view
        returns (TrancheData memory, uint256[] memory)
    {
        TrancheData memory td;
        uint256[] memory collateralBalances;
        uint256[] memory trancheSupplies;

        (td, collateralBalances, trancheSupplies) = getTrancheCollateralizations(b);

        uint256[] memory balances = new uint256[](td.trancheCount);
        for (uint8 i = 0; i < td.trancheCount; i++) {
            balances[i] = (td.tranches[i].balanceOf(u) * collateralBalances[i]) / trancheSupplies[i];
        }

        return (td, balances);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface ITranche is IERC20Upgradeable {
    function bond() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import { ITranche } from "./ITranche.sol";

interface IBondController {
    function collateralToken() external view returns (address);

    function maturityDate() external view returns (uint256);

    function creationDate() external view returns (uint256);

    function totalDebt() external view returns (uint256);

    function feeBps() external view returns (uint256);

    function isMature() external view returns (bool);

    function tranches(uint256 i) external view returns (ITranche token, uint256 ratio);

    function trancheCount() external view returns (uint256 count);

    function deposit(uint256 amount) external;

    function redeem(uint256[] memory amounts) external;

    function mature() external;

    function redeemMature(address tranche, uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import { IBondIssuer } from "./IBondIssuer.sol";
import { IFeeStrategy } from "./IFeeStrategy.sol";
import { IPricingStrategy } from "./IPricingStrategy.sol";
import { IYieldStrategy } from "./IYieldStrategy.sol";
import { IBondController } from "./buttonwood/IBondController.sol";
import { ITranche } from "./buttonwood/ITranche.sol";

interface IPerpetualTranche is IERC20Upgradeable {
    //--------------------------------------------------------------------------
    // Events

    // @notice Event emitted when the bond issuer is updated.
    // @param issuer Address of the issuer contract.
    event UpdatedBondIssuer(IBondIssuer issuer);

    // @notice Event emitted when the fee strategy is updated.
    // @param strategy Address of the strategy contract.
    event UpdatedFeeStrategy(IFeeStrategy strategy);

    // @notice Event emitted when the pricing strategy is updated.
    // @param strategy Address of the strategy contract.
    event UpdatedPricingStrategy(IPricingStrategy strategy);

    // @notice Event emitted when the yield strategy is updated.
    // @param strategy Address of the strategy contract.
    event UpdatedYieldStrategy(IYieldStrategy strategy);

    // @notice Event emitted when maturity tolerance parameters are updated.
    // @param min The minimum maturity time.
    // @param max The maximum maturity time.
    event UpdatedTolerableTrancheMaturiy(uint256 min, uint256 max);

    // @notice Event emitted when the max total supply is updated.
    // @param maxSupply The max total supply.
    // @param maxMintAmtPerTranche The max mint amount per tranche.
    event UpdatedMintingLimits(uint256 maxSupply, uint256 maxMintAmtPerTranche);

    // @notice Event emitted when the skim percentage is updated.
    // @param skimPerc The skim percentage.
    event UpdatedSkimPerc(uint256 skimPerc);

    // @notice Event emitted when the applied yield for a given token is set.
    // @param token The address of the token.
    // @param yield The yield factor applied.
    event YieldApplied(IERC20Upgradeable token, uint256 yield);

    // @notice Event emitted the reserve's current token balance is recorded after change.
    // @param token Address of token.
    // @param balance The recorded ERC-20 balance of the token held by the reserve.
    event ReserveSynced(IERC20Upgradeable token, uint256 balance);

    // @notice Event emitted when the active deposit bond is updated.
    // @param bond Address of the new deposit bond.
    event UpdatedDepositBond(IBondController bond);

    // @notice Event emitted when the standardized total tranche balance is updated.
    // @param stdTotalTrancheBalance The standardized total tranche balance.
    event UpdatedStdTotalTrancheBalance(uint256 stdTotalTrancheBalance);

    // @notice Event emitted when the standardized mature tranche balance is updated.
    // @param stdMatureTrancheBalance The standardized mature tranche balance.
    event UpdatedStdMatureTrancheBalance(uint256 stdMatureTrancheBalance);

    //--------------------------------------------------------------------------
    // Methods

    // @notice Deposits tranche tokens into the system and mint perp tokens.
    // @param trancheIn The address of the tranche token to be deposited.
    // @param trancheInAmt The amount of tranche tokens deposited.
    function deposit(ITranche trancheIn, uint256 trancheInAmt) external;

    // @notice Burn perp tokens and redeem the share of reserve assets.
    // @param perpAmtBurnt The amount of perp tokens burnt from the caller.
    function burn(uint256 perpAmtBurnt) external;

    // @notice Rotates newer tranches in for reserve tokens.
    // @param trancheIn The tranche token deposited.
    // @param tokenOut The reserve token to be redeemed.
    // @param trancheInAmt The amount of trancheIn tokens deposited.
    function rollover(
        ITranche trancheIn,
        IERC20Upgradeable tokenOut,
        uint256 trancheInAmt
    ) external;

    // @notice Burn perp tokens without redemption.
    // @param amount Amount of perp tokens to be burnt.
    // @return True if burn is successful.
    function burnWithoutRedemption(uint256 amount) external returns (bool);

    // @notice The address of the underlying rebasing ERC-20 collateral token backing the tranches.
    // @return Address of the collateral token.
    function collateral() external view returns (IERC20Upgradeable);

    // @notice The "standardized" balances of all tranches deposited into the system.
    // @return stdTotalTrancheBalance The "standardized" total tranche balance.
    // @return stdMatureTrancheBalance The "standardized" mature tranche balance.
    function getStdTrancheBalances() external returns (uint256 stdTotalTrancheBalance, uint256 stdMatureTrancheBalance);

    // @notice The parent bond whose tranches are currently accepted to mint perp tokens.
    // @return Address of the deposit bond.
    function getDepositBond() external returns (IBondController);

    // @notice Checks if the given `trancheIn` can be rolled out for `tokenOut`.
    // @param trancheIn The tranche token deposited.
    // @param tokenOut The reserve token to be redeemed.
    function isAcceptableRollover(ITranche trancheIn, IERC20Upgradeable tokenOut) external returns (bool);

    // @notice The strategy contract with the fee computation logic.
    // @return Address of the strategy contract.
    function feeStrategy() external view returns (IFeeStrategy);

    // @notice The contract where the protocol holds funds which back the perp token supply.
    // @return Address of the reserve.
    function reserve() external view returns (address);

    // @notice The contract where the protocol holds the cash from fees.
    // @return Address of the fee collector.
    function feeCollector() external view returns (address);

    // @notice The fee token currently used to receive fees in.
    // @return Address of the fee token.
    function feeToken() external view returns (IERC20Upgradeable);

    // @notice Total count of tokens held in the reserve.
    function getReserveCount() external returns (uint256);

    // @notice The token address from the reserve list by index.
    // @param index The index of a token.
    function getReserveAt(uint256 index) external returns (IERC20Upgradeable);

    // @notice Checks if the given token is part of the reserve.
    // @param token The address of a token to check.
    function isReserveToken(IERC20Upgradeable token) external returns (bool);

    // @notice Checks if the given token is a tranche token part of the reserve.
    // @param token The address of a reserve token to check.
    function isReserveTranche(IERC20Upgradeable token) external returns (bool);

    // @notice Fetches the reserve's token balance.
    // @param token The address of the reserve token.
    function getReserveBalance(IERC20Upgradeable token) external returns (uint256);

    // @notice Computes the total value of all reserve assets.
    function getReserveValue() external returns (uint256);

    // @notice Fetches the list of reserve tokens which are up for rollover.
    function getReserveTokensUpForRollover() external returns (IERC20Upgradeable[] memory);

    // @notice Computes the amount of perp tokens minted when `trancheInAmt` `trancheIn` tokens
    //         are deposited into the system.
    // @param trancheIn The tranche token deposited.
    // @param trancheInAmt The amount of tranche tokens deposited.
    // @return perpAmtMinted The amount of perp tokens to be minted.
    // @return stdTrancheAmt The standardized tranche amount deposited.
    function computeMintAmt(ITranche trancheIn, uint256 trancheInAmt)
        external
        returns (uint256 perpAmtMinted, uint256 stdTrancheAmt);

    // @notice Computes the amount reserve tokens redeemed when burning given number of perp tokens.
    // @param perpAmtBurnt The amount of perp tokens to be burnt.
    // @return tokensOut The list of reserve tokens redeemed.
    // @return tokenOutAmts The list of reserve token amounts redeemed.
    function computeRedemptionAmts(uint256 perpAmtBurnt)
        external
        returns (IERC20Upgradeable[] memory tokensOut, uint256[] memory tokenOutAmts);

    struct RolloverPreview {
        // @notice The perp denominated value of tokens rolled over.
        uint256 perpRolloverAmt;
        // @notice The amount of tokens to be withdrawn.
        uint256 tokenOutAmt;
        // @notice The standardized tranche amount rolled over.
        uint256 stdTrancheRolloverAmt;
        // @notice The amount of trancheIn tokens used in the roll over operation.
        uint256 trancheInAmtUsed;
        // @notice The difference between the requested trancheIn amount and the amount used for the rollover.
        uint256 remainingTrancheInAmt;
    }

    // @notice Computes the amount reserve tokens that can be swapped out for the given number
    //         of `trancheIn` tokens.
    // @param trancheIn The tranche token deposited.
    // @param tokenOut The reserve token to be withdrawn.
    // @param trancheInAmtRequested The maximum amount of trancheIn tokens deposited.
    // @param maxTokenOutAmtCovered The reserve token balance available for rollover.
    // @return r The rollover amounts in various denominations.
    function computeRolloverAmt(
        ITranche trancheIn,
        IERC20Upgradeable tokenOut,
        uint256 trancheInAmtRequested,
        uint256 maxTokenOutAmtCovered
    ) external returns (RolloverPreview memory);

    // @notice The yield to be applied given the reserve token.
    // @param token The address of the reserve token.
    // @return The yield applied.
    function computeYield(IERC20Upgradeable token) external view returns (uint256);

    // @notice The price of the given reserve token.
    // @param token The address of the reserve token.
    // @return The computed price.
    function computePrice(IERC20Upgradeable token) external view returns (uint256);

    // @notice Updates time dependent storage state.
    function updateState() external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import { IBondController } from "./buttonwood/IBondController.sol";

interface IBondIssuer {
    /// @notice Event emitted when a new bond is issued by the issuer.
    /// @param bond The newly issued bond.
    event BondIssued(IBondController bond);

    // @notice Issues a new bond if sufficient time has elapsed since the last issue.
    function issue() external;

    // @notice Checks if a given bond has been issued by the issuer.
    // @param Address of the bond to check.
    // @return if the bond has been issued by the issuer.
    function isInstance(IBondController bond) external view returns (bool);

    // @notice Fetches the most recently issued bond.
    // @return Address of the most recent bond.
    function getLatestBond() external returns (IBondController);

    // @notice Returns the total number of bonds issued by this issuer.
    // @return Number of bonds.
    function issuedCount() external view returns (uint256);

    // @notice The bond address from the issued list by index.
    // @return Address of the bond.
    function issuedBondAt(uint256 index) external view returns (IBondController);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IFeeStrategy {
    // @notice Address of the fee token.
    function feeToken() external view returns (IERC20Upgradeable);

    // @notice Computes the fee to mint given amount of perp tokens.
    // @dev Fee can be either positive or negative. When positive it's paid by the minting users to the system.
    //      When negative its paid to the minting users by the system.
    // @param amount The amount of perp tokens to be minted.
    // @return The mint fee in fee tokens.
    function computeMintFee(uint256 amount) external view returns (int256);

    // @notice Computes the fee to burn given amount of perp tokens.
    // @dev Fee can be either positive or negative. When positive it's paid by the burning users to the system.
    //      When negative its paid to the burning users by the system.
    // @param amount The amount of perp tokens to be burnt.
    // @return The burn fee in fee tokens.
    function computeBurnFee(uint256 amount) external view returns (int256);

    // @notice Computes the fee to rollover given amount of perp tokens.
    // @dev Fee can be either positive or negative. When positive it's paid by the users rolling over to the system.
    //      When negative its paid to the users rolling over by the system.
    // @param amount The Perp-denominated value of the tranches being rotated in.
    // @return The rollover fee in fee tokens.
    function computeRolloverFee(uint256 amount) external view returns (int256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { ITranche } from "../_interfaces/buttonwood/ITranche.sol";

interface IPricingStrategy {
    // @notice Computes the price of a given tranche token.
    // @param tranche The tranche to compute price of.
    // @return The price as a fixed point number with `decimals()`.
    function computeTranchePrice(ITranche tranche) external view returns (uint256);

    // @notice Computes the price of mature tranches extracted and held as naked collateral.
    // @param collateralToken The collateral token.
    // @param collateralBalance The collateral balance of all the mature tranches.
    // @param debt The total count of mature tranches.
    // @return The price as a fixed point number with `decimals()`.
    function computeMatureTranchePrice(
        IERC20Upgradeable collateralToken,
        uint256 collateralBalance,
        uint256 debt
    ) external view returns (uint256);

    // @notice Number of price decimals.
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IYieldStrategy {
    // @notice Computes the yield to be applied to a given token.
    // @param token The token to compute yield for.
    // @return The yield as a fixed point number with `decimals()`.
    function computeYield(IERC20Upgradeable token) external view returns (uint256);

    // @notice Number of yield decimals.
    function decimals() external view returns (uint8);
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
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
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
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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