// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import { MathUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import { SignedMathUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/math/SignedMathUpgradeable.sol";

import { ERC20BurnableUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import { EnumerableSetUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import { BondHelpers } from "./_utils/BondHelpers.sol";

import { IERC20MetadataUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import { IERC20Upgradeable, IPerpetualTranche, IBondIssuer, IFeeStrategy, IPricingStrategy, IDiscountStrategy, IBondController, ITranche } from "./_interfaces/IPerpetualTranche.sol";

/// @notice Expected contract call to be triggered by authorized caller.
/// @param caller The address which triggered the call.
/// @param authorizedCaller The address which is authorized to trigger the call.
error UnauthorizedCall(address caller, address authorizedCaller);

/// @notice Expected a valid percentage value from 0-100 as a fixed point number with {PERC_DECIMALS}.
/// @param value Invalid value.
error InvalidPerc(uint256 value);

/// @notice Expected contract reference to not be `address(0)`.
error UnacceptableReference();

/// @notice Expected strategy to return a fixed point with exactly expected decimals.
error InvalidStrategyDecimals(uint256 decimals, uint256 expectDecimals);

/// @notice Expected bond issuer's collateral token to match underlying collateral token.
/// @param  invalidCollateral Address of the input bond issuer's collateral token.
/// @param underlyingCollateral Address of underlying system collateral token.
error InvalidCollateral(address invalidCollateral, address underlyingCollateral);

/// @notice Expected minTrancheMaturity be less than or equal to maxTrancheMaturity.
/// @param minTrancheMaturitySec Minimum tranche maturity time in seconds.
/// @param minTrancheMaturitySec Maximum tranche maturity time in seconds.
error InvalidTrancheMaturityBounds(uint256 minTrancheMaturitySec, uint256 maxTrancheMaturitySec);

/// @notice Expected deposited tranche to be of current deposit bond.
/// @param trancheIn Address of the deposit tranche.
/// @param depositBond Address of the currently accepted deposit bond.
error UnacceptableDepositTranche(ITranche trancheIn, IBondController depositBond);

/// @notice Expected to mint a non-zero amount of tokens.
/// @param trancheInAmt The amount of tranche tokens deposited.
/// @param perpAmtMint The amount of tranche tokens mint.
error UnacceptableMintAmt(uint256 trancheInAmt, uint256 perpAmtMint);

/// @notice Expected to burn a non-zero amount of tokens.
/// @param requestedBurnAmt The amount of tranche tokens requested to be burnt.
/// @param perpSupply The current supply of perp tokens.
error UnacceptableBurnAmt(uint256 requestedBurnAmt, uint256 perpSupply);

/// @notice Expected redemption to result in supply reduction.
/// @param newSupply The new total supply after redemption.
/// @param perpSupply The current supply of perp tokens.
error ExpectedSupplyReduction(uint256 newSupply, uint256 perpSupply);

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

/// @notice Expected the percentage of reserve value held as mature tranches to be at least
///         as much as the target percentage.
/// @param matureValuePerc The current percentage of reserve value held as mature tranches.
/// @param matureValueTargetPerc The target percentage.
error BelowMatureValueTargetPerc(uint256 matureValuePerc, uint256 matureValueTargetPerc);

/// @notice Expected transfer out asset to not be a reserve asset.
/// @param token Address of the token transferred.
error UnauthorizedTransferOut(IERC20Upgradeable token);

/**
 *  @title PerpetualTranche
 *
 *  @notice An opinionated implementation of a perpetual note ERC-20 token contract, backed by buttonwood tranches.
 *
 *          Perpetual note tokens (or perps for short) are backed by tranche tokens held in this contract's reserve.
 *          Users can mint perps by depositing tranche tokens into the reserve.
 *          They can redeem tokens from the reserve by burning their perps.
 *
 *          The whitelisted bond issuer issues new deposit bonds periodically based on a predefined frequency.
 *          Users can ONLY mint perps for tranche tokens belonging to the active "deposit" bond.
 *          Users can burn perps, and redeem a proportional share of tokens held in the reserve.
 *
 *          Once tranche tokens held in the reserve mature the underlying collateral is extracted
 *          into the reserve. The system keeps track of total mature tranches held by the reserve.
 *          This acts as a "virtual" tranche balance for all collateral extracted from the mature tranches.
 *
 *          At any time, the reserve holds at most 2 classes of tokens
 *          ie) the normal tranche tokens and mature tranche (which is essentially the underlying collateral token).
 *
 *          Incentivized parties can "rollover" tranches approaching maturity or the mature tranche,
 *          for newer tranche tokens that belong to the current "depositBond".
 *
 *          The time dependent system state is updated "lazily" without a need for an explicit poke
 *          from the outside world. Every external function that deals with the reserve
 *          invokes the `afterStateUpdate` modifier at the entry-point.
 *          This brings the system storage state up to date.
 *
 */
contract PerpetualTranche is
    ERC20BurnableUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    IPerpetualTranche
{
    // data handling
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using BondHelpers for IBondController;

    // ERC20 operations
    using SafeERC20Upgradeable for IERC20Upgradeable;

    //-------------------------------------------------------------------------
    // Perp Math Basics:
    //
    // System holds tokens in the reserve {t1, t2 ... tn}
    // with balances {b1, b2 ... bn}.
    //
    // Internally reserve token denominations (amounts/balances) are
    // standardized using a discount factor.
    // Standard denomination: b'i = bi . discount(ti)
    //
    // Discount are typically expected to be ~1.0 for safe tranches,
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
    // When `ai` tokens of type `ti` are rotated in for tokens of type `tj`
    //  => ai * discount(ti) * price(ti) =  aj * discount(tj) * price(tj)
    // Rotation: aj => ai * discount(ti) * price(ti) / (discount(tj) * price(tj))
    //
    //
    //-------------------------------------------------------------------------
    // Constants & Immutables
    uint8 public constant DISCOUNT_DECIMALS = 18;
    uint256 public constant UNIT_DISCOUNT = (10**DISCOUNT_DECIMALS);

    uint8 public constant PRICE_DECIMALS = 8;
    uint256 public constant UNIT_PRICE = (10**PRICE_DECIMALS);

    uint8 public constant PERC_DECIMALS = 6;
    uint256 public constant UNIT_PERC = 10**PERC_DECIMALS;
    uint256 public constant HUNDRED_PERC = 100 * UNIT_PERC;

    //-------------------------------------------------------------------------
    // Storage

    /// @dev The perp token balances are represented as a fixed point unsigned integer with these many decimals.
    uint8 private _decimals;

    //--------------------------------------------------------------------------
    // CONFIG

    /// @inheritdoc IPerpetualTranche
    address public override keeper;

    /// @notice External contract points controls fees & incentives.
    IFeeStrategy public override feeStrategy;

    /// @notice External contract that computes a given reserve token's price.
    /// @dev The computed price is expected to be a fixed point unsigned integer with {PRICE_DECIMALS} decimals.
    IPricingStrategy public pricingStrategy;

    /// @notice External contract that computes a given reserve token's discount factor.
    /// @dev It is a multiplier, applied to every asset when added to the reserve.
    ///      This accounts for things like tranche seniority and underlying collateral volatility.
    ///      It also allows for standardizing denominations when comparing two different reserve tokens.
    ///      For example, a factor of 0.95 on a particular tranche results in a 5% discount.
    ///      The discount factor is expected to be a fixed point unsigned integer with {DISCOUNT_DECIMALS} decimals.
    IDiscountStrategy public discountStrategy;

    /// @notice External contract that stores a predefined bond config and frequency,
    ///         and issues new bonds when poked.
    /// @dev Only tranches of bonds issued by this whitelisted issuer are accepted into the reserve.
    IBondIssuer public bondIssuer;

    /// @notice The active deposit bond of whose tranches are currently being accepted to mint perps.
    IBondController private _depositBond;

    /// @notice The minimum maturity time in seconds for a tranche below which
    ///         it can be rolled over.
    uint256 public minTrancheMaturitySec;

    /// @notice The maximum maturity time in seconds for a tranche above which
    ///         it can NOT get added into the reserve.
    uint256 public maxTrancheMaturitySec;

    /// @notice The percentage of the reserve value to be held as mature tranches.
    uint256 public matureValueTargetPerc;

    /// @notice The maximum supply of perps that can exist at any given time.
    uint256 public maxSupply;

    /// @notice The max number of perps that can be minted for each tranche in the minting bond.
    uint256 public maxMintAmtPerTranche;

    /// @notice The total number of perps that have been minted using a given tranche.
    mapping(ITranche => uint256) public mintedSupplyPerTranche;

    /// @notice Discount factor actually "applied" on each reserve token. It is computed and recorded when
    ///         a token is deposited into the system for the first time.
    /// @dev For all calculations thereafter, the token's applied discount will be used.
    ///      The discount is stored as a fixed point unsigned integer with {DISCOUNT_DECIMALS} decimals.
    mapping(IERC20Upgradeable => uint256) private _appliedDiscounts;

    //--------------------------------------------------------------------------
    // RESERVE

    /// @notice A record of all tokens in the reserve which back the perps.
    EnumerableSetUpgradeable.AddressSet private _reserves;

    /// @notice The amount of all the mature tranches extracted and held as the collateral token,
    ///         i.e) the reserve's "virtual" mature tranche balance.
    /// @dev The mature tranche is assumed to have {UNIT_DISCOUNT}. So we do NOT have to
    ///      scale using the discount factor when dealing with the mature tranche balance.
    uint256 private _matureTrancheBalance;

    //--------------------------------------------------------------------------
    // Modifiers

    /// @dev Updates time-dependent reserve state.
    modifier afterStateUpdate() {
        updateState();
        _;
    }

    /// @dev Throws if called by any account other than the keeper.
    modifier onlyKeeper() {
        if (keeper != _msgSender()) {
            revert UnauthorizedCall(_msgSender(), keeper);
        }
        _;
    }

    //--------------------------------------------------------------------------
    // Construction & Initialization

    /// @notice Contract state initialization.
    /// @param name ERC-20 Name of the Perp token.
    /// @param symbol ERC-20 Symbol of the Perp token.
    /// @param collateral_ Address of the underlying collateral token.
    /// @param bondIssuer_ Address of the bond issuer contract.
    /// @param feeStrategy_ Address of the fee strategy contract.
    /// @param pricingStrategy_ Address of the pricing strategy contract.
    /// @param discountStrategy_ Address of the discount strategy contract.
    function init(
        string memory name,
        string memory symbol,
        IERC20Upgradeable collateral_,
        IBondIssuer bondIssuer_,
        IFeeStrategy feeStrategy_,
        IPricingStrategy pricingStrategy_,
        IDiscountStrategy discountStrategy_
    ) public initializer {
        __ERC20_init(name, symbol);
        __Ownable_init();
        _decimals = IERC20MetadataUpgradeable(address(collateral_)).decimals();

        // NOTE: `_reserveAt(0)` always points to the underling collateral token
        // and is to be never updated.
        _reserves.add(address(collateral_));
        _syncReserve(collateral_);
        _applyDiscount(collateral_, UNIT_DISCOUNT);

        updateBondIssuer(bondIssuer_);
        updateFeeStrategy(feeStrategy_);
        updatePricingStrategy(pricingStrategy_);
        updateDiscountStrategy(discountStrategy_);

        updateTolerableTrancheMaturity(1, type(uint256).max);
        updateMintingLimits(type(uint256).max, type(uint256).max);
        updateMatureValueTargetPerc(0);
    }

    //--------------------------------------------------------------------------
    // ADMIN only methods

    /// @notice Pauses deposits, withdrawals and rollovers.
    /// @dev NOTE: ERC-20 functions, like transfers will always remain operational.
    function pause() public onlyKeeper {
        _pause();
    }

    /// @notice Unpauses deposits, withdrawals and rollovers.
    /// @dev NOTE: ERC-20 functions, like transfers will always remain operational.
    function unpause() public onlyKeeper {
        _unpause();
    }

    /// @notice Updates the reference to the keeper.
    /// @param newKeeper The address of the new keeper.
    function updateKeeper(address newKeeper) public virtual onlyOwner {
        if (newKeeper == address(0)) {
            revert UnacceptableReference();
        }
        address prevKeeper = keeper;
        keeper = newKeeper;
        emit UpdatedKeeper(prevKeeper, newKeeper);
    }

    /// @notice Update the reference to the bond issuer contract.
    /// @param bondIssuer_ New bond issuer address.
    function updateBondIssuer(IBondIssuer bondIssuer_) public onlyOwner {
        if (address(bondIssuer_) == address(0)) {
            revert UnacceptableReference();
        }
        if (address(_reserveAt(0)) != bondIssuer_.collateral()) {
            revert InvalidCollateral(bondIssuer_.collateral(), address(_reserveAt(0)));
        }
        bondIssuer = bondIssuer_;
        emit UpdatedBondIssuer(bondIssuer_);
    }

    /// @notice Update the reference to the fee strategy contract.
    /// @param feeStrategy_ New strategy address.
    function updateFeeStrategy(IFeeStrategy feeStrategy_) public onlyOwner {
        if (address(feeStrategy_) == address(0)) {
            revert UnacceptableReference();
        }
        feeStrategy = feeStrategy_;
        emit UpdatedFeeStrategy(feeStrategy_);
    }

    /// @notice Update the reference to the pricing strategy contract.
    /// @param pricingStrategy_ New strategy address.
    function updatePricingStrategy(IPricingStrategy pricingStrategy_) public onlyOwner {
        if (address(pricingStrategy_) == address(0)) {
            revert UnacceptableReference();
        }
        if (pricingStrategy_.decimals() != PRICE_DECIMALS) {
            revert InvalidStrategyDecimals(pricingStrategy_.decimals(), PRICE_DECIMALS);
        }
        pricingStrategy = pricingStrategy_;
        emit UpdatedPricingStrategy(pricingStrategy_);
    }

    /// @notice Update the reference to the discount strategy contract.
    /// @param discountStrategy_ New strategy address.
    function updateDiscountStrategy(IDiscountStrategy discountStrategy_) public onlyOwner {
        if (address(discountStrategy_) == address(0)) {
            revert UnacceptableReference();
        }
        if (discountStrategy_.decimals() != DISCOUNT_DECIMALS) {
            revert InvalidStrategyDecimals(discountStrategy_.decimals(), DISCOUNT_DECIMALS);
        }
        discountStrategy = discountStrategy_;
        emit UpdatedDiscountStrategy(discountStrategy_);
    }

    /// @notice Update the maturity tolerance parameters.
    /// @param minTrancheMaturitySec_ New minimum maturity time.
    /// @param maxTrancheMaturitySec_ New maximum maturity time.
    function updateTolerableTrancheMaturity(uint256 minTrancheMaturitySec_, uint256 maxTrancheMaturitySec_)
        public
        onlyOwner
    {
        if (minTrancheMaturitySec_ > maxTrancheMaturitySec_) {
            revert InvalidTrancheMaturityBounds(minTrancheMaturitySec_, maxTrancheMaturitySec_);
        }
        minTrancheMaturitySec = minTrancheMaturitySec_;
        maxTrancheMaturitySec = maxTrancheMaturitySec_;
        emit UpdatedTolerableTrancheMaturity(minTrancheMaturitySec_, maxTrancheMaturitySec_);
    }

    /// @notice Update parameters controlling the perp token mint limits.
    /// @param maxSupply_ New max total supply.
    /// @param maxMintAmtPerTranche_ New max total for per tranche in minting bond.
    function updateMintingLimits(uint256 maxSupply_, uint256 maxMintAmtPerTranche_) public onlyOwner {
        maxSupply = maxSupply_;
        maxMintAmtPerTranche = maxMintAmtPerTranche_;
        emit UpdatedMintingLimits(maxSupply_, maxMintAmtPerTranche_);
    }

    /// @notice Update the mature value target percentage parameter.
    /// @param matureValueTargetPerc_ The new target percentage.
    function updateMatureValueTargetPerc(uint256 matureValueTargetPerc_) public onlyOwner {
        if (matureValueTargetPerc_ > HUNDRED_PERC) {
            revert InvalidPerc(matureValueTargetPerc_);
        }
        matureValueTargetPerc = matureValueTargetPerc_;
        emit UpdatedMatureValueTargetPerc(matureValueTargetPerc);
    }

    /// @notice Allows the owner to transfer non-critical assets out of the system if required.
    /// @param token The token address.
    /// @param to The destination address.
    /// @param amount The amount of tokens to be transferred.
    function transferERC20(
        IERC20Upgradeable token,
        address to,
        uint256 amount
    ) external afterStateUpdate onlyOwner {
        if (_inReserve(token) || feeToken() == token) {
            revert UnauthorizedTransferOut(token);
        }
        token.safeTransfer(to, amount);
    }

    //--------------------------------------------------------------------------
    // External methods

    /// @inheritdoc IPerpetualTranche
    function deposit(ITranche trancheIn, uint256 trancheInAmt)
        external
        override
        nonReentrant
        whenNotPaused
        afterStateUpdate
    {
        if (!_isBondTranche(trancheIn, _depositBond)) {
            revert UnacceptableDepositTranche(trancheIn, _depositBond);
        }

        // calculates the amount of perp tokens when depositing `trancheInAmt` of tranche tokens
        uint256 perpAmtMint = _computeMintAmt(trancheIn, trancheInAmt);
        if (trancheInAmt == 0 || perpAmtMint == 0) {
            revert UnacceptableMintAmt(trancheInAmt, perpAmtMint);
        }

        // calculates the fees to mint `perpAmtMint` of perp token
        (int256 reserveFee, uint256 protocolFee) = feeStrategy.computeMintFees(perpAmtMint);

        // transfers tranche tokens from the sender to the reserve
        _transferIntoReserve(msg.sender, trancheIn, trancheInAmt);

        // mints perp tokens to the sender
        _mint(msg.sender, perpAmtMint);

        // settles fees
        _settleFee(msg.sender, reserveFee, protocolFee);

        // post-deposit checks
        mintedSupplyPerTranche[trancheIn] += perpAmtMint;
        _enforcePerTrancheSupplyCap(trancheIn);
        _enforceTotalSupplyCap();
    }

    /// @inheritdoc IPerpetualTranche
    function redeem(uint256 perpAmtBurnt) external override nonReentrant whenNotPaused afterStateUpdate {
        // gets the current perp supply
        uint256 perpSupply = totalSupply();

        // verifies if burn amount is acceptable
        if (perpAmtBurnt == 0 || perpAmtBurnt > perpSupply) {
            revert UnacceptableBurnAmt(perpAmtBurnt, perpSupply);
        }

        // calculates share of reserve tokens to be redeemed
        (IERC20Upgradeable[] memory tokensOuts, uint256[] memory tokenOutAmts) = _computeRedemptionAmts(perpAmtBurnt);

        // calculates the fees to burn `perpAmtBurnt` of perp token
        (int256 reserveFee, uint256 protocolFee) = feeStrategy.computeBurnFees(perpAmtBurnt);

        // updates the mature tranche balance
        _updateMatureTrancheBalance((_matureTrancheBalance * (perpSupply - perpAmtBurnt)) / perpSupply);

        // settles fees
        _settleFee(msg.sender, reserveFee, protocolFee);

        // burns perp tokens from the sender
        _burn(msg.sender, perpAmtBurnt);

        // transfers reserve tokens out
        for (uint256 i = 0; i < tokensOuts.length; i++) {
            if (tokenOutAmts[i] > 0) {
                _transferOutOfReserve(msg.sender, tokensOuts[i], tokenOutAmts[i]);
            }
        }

        // post-redeem checks
        _enforceSupplyReduction(perpSupply);
    }

    /// @inheritdoc IPerpetualTranche
    function rollover(
        ITranche trancheIn,
        IERC20Upgradeable tokenOut,
        uint256 trancheInAmtAvailable
    ) external override nonReentrant whenNotPaused afterStateUpdate {
        // verifies if rollover is acceptable
        if (!_isAcceptableRollover(trancheIn, tokenOut)) {
            revert UnacceptableRollover(trancheIn, tokenOut);
        }

        // calculates the perp denominated amount rolled over and the tokenOutAmt
        IPerpetualTranche.RolloverPreview memory r = _computeRolloverAmt(
            trancheIn,
            tokenOut,
            trancheInAmtAvailable,
            type(uint256).max
        );

        // verifies if rollover amount is acceptable
        if (r.trancheInAmt == 0 || r.tokenOutAmt == 0 || r.perpRolloverAmt == 0) {
            revert UnacceptableRolloverAmt(r.trancheInAmt, r.tokenOutAmt, r.perpRolloverAmt);
        }

        // calculates the fees to rollover `r.perpRolloverAmt` of perp token
        (int256 reserveFee, uint256 protocolFee) = feeStrategy.computeRolloverFees(r.perpRolloverAmt);

        // transfers tranche tokens from the sender to the reserve
        _transferIntoReserve(msg.sender, trancheIn, r.trancheInAmt);

        // settles fees
        _settleFee(msg.sender, reserveFee, protocolFee);

        // updates the mature tranche balance
        if (_isMatureTranche(tokenOut)) {
            _updateMatureTrancheBalance(_matureTrancheBalance - r.trancheOutAmt);
        }

        // transfers tranche from the reserve to the sender
        _transferOutOfReserve(msg.sender, tokenOut, r.tokenOutAmt);

        // post-rollover checks
        _enforceMatureValueTarget();
        _enforceTotalSupplyCap();
    }

    /// @inheritdoc IPerpetualTranche
    function getMatureTrancheBalance() external override afterStateUpdate returns (uint256) {
        return _matureTrancheBalance;
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
    function inReserve(IERC20Upgradeable token) external override afterStateUpdate returns (bool) {
        return _inReserve(token);
    }

    /// @inheritdoc IPerpetualTranche
    function getReserveTrancheBalance(IERC20Upgradeable tranche) external override afterStateUpdate returns (uint256) {
        if (!_inReserve(tranche)) {
            return 0;
        }
        return _isMatureTranche(tranche) ? _matureTrancheBalance : _reserveBalance(tranche);
    }

    /// @inheritdoc IPerpetualTranche
    /// @dev Reserve tokens which are not up for rollover are marked by `address(0)`.
    function getReserveTokensUpForRollover() external override afterStateUpdate returns (IERC20Upgradeable[] memory) {
        uint256 reserveCount = _reserveCount();
        IERC20Upgradeable[] memory rolloverTokens = new IERC20Upgradeable[](reserveCount);

        if (_matureTrancheBalance > 0) {
            rolloverTokens[0] = _reserveAt(0);
        }

        // Iterating through the reserve to find tranches that are no longer "acceptable"
        for (uint256 i = 1; i < reserveCount; i++) {
            IERC20Upgradeable token = _reserveAt(i);
            IBondController bond = IBondController(ITranche(address(token)).bond());
            if (!_isAcceptableForReserve(bond)) {
                rolloverTokens[i] = token;
            }
        }

        return rolloverTokens;
    }

    /// @inheritdoc IPerpetualTranche
    /// @dev Returns a fixed point with {PRICE_DECIMALS} decimals.
    function getAvgPrice() external override afterStateUpdate returns (uint256) {
        uint256 totalSupply_ = totalSupply();
        return totalSupply_ > 0 ? _reserveValue() / totalSupply_ : 0;
    }

    /// @inheritdoc IPerpetualTranche
    function computeMintAmt(ITranche trancheIn, uint256 trancheInAmt)
        external
        override
        afterStateUpdate
        returns (uint256)
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
    /// @dev Set `tokenOutAmtRequested` to max(uint256) to use the reserve balance.
    function computeRolloverAmt(
        ITranche trancheIn,
        IERC20Upgradeable tokenOut,
        uint256 trancheInAmtAvailable,
        uint256 tokenOutAmtRequested
    ) external override afterStateUpdate returns (IPerpetualTranche.RolloverPreview memory) {
        return _computeRolloverAmt(trancheIn, tokenOut, trancheInAmtAvailable, tokenOutAmtRequested);
    }

    //--------------------------------------------------------------------------
    // Public methods

    /// @inheritdoc IPerpetualTranche
    /// @dev Lazily updates time-dependent reserve storage state.
    ///      This function is to be invoked on all external function entry points which are
    ///      read the reserve storage. This function is intended to be idempotent.
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
        //       We also skip the `reserveAt(0)`, i.e) the mature tranche,
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

            // Redeeming the underlying collateral token
            uint256 trancheBalance = _reserveBalance(tranche);
            bond.redeemMature(address(tranche), trancheBalance);
            _syncReserve(tranche);

            // Keeps track of the total tranches redeemed
            _updateMatureTrancheBalance(
                _matureTrancheBalance + _toStdTrancheAmt(trancheBalance, computeDiscount(tranche))
            );
        }

        // Keeps track of the mature tranche's underlying balance
        // ie) the rebasing collateral token
        _syncReserve(_reserveAt(0));
    }

    //--------------------------------------------------------------------------
    // External view methods

    /// @inheritdoc IPerpetualTranche
    function collateral() external view override returns (IERC20Upgradeable) {
        return _reserveAt(0);
    }

    //--------------------------------------------------------------------------
    // Public view methods

    /// @inheritdoc IPerpetualTranche
    function perpERC20() public view override returns (IERC20Upgradeable) {
        return IERC20Upgradeable(address(this));
    }

    /// @inheritdoc IPerpetualTranche
    function reserve() public view override returns (address) {
        return address(this);
    }

    /// @inheritdoc IPerpetualTranche
    function protocolFeeCollector() public view override returns (address) {
        return owner();
    }

    /// @inheritdoc IPerpetualTranche
    function feeToken() public view override returns (IERC20Upgradeable) {
        return feeStrategy.feeToken();
    }

    /// @inheritdoc IPerpetualTranche
    /// @dev Gets the applied discount for the given tranche if it's set,
    ///      if NOT computes the discount.
    function computeDiscount(IERC20Upgradeable token) public view override returns (uint256) {
        uint256 discount = _appliedDiscounts[token];
        return (discount > 0) ? discount : discountStrategy.computeTrancheDiscount(token);
    }

    /// @inheritdoc IPerpetualTranche
    function computePrice(IERC20Upgradeable token) public view override returns (uint256) {
        return
            _isMatureTranche(token)
                ? pricingStrategy.computeMatureTranchePrice(token, _reserveBalance(token), _matureTrancheBalance)
                : pricingStrategy.computeTranchePrice(ITranche(address(token)));
    }

    /// @notice Returns the number of decimals used to get its user representation.
    /// @dev For example, if `decimals` equals `2`, a balance of `505` tokens should
    ///      be displayed to a user as `5.05` (`505 / 10 ** 2`).
    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    //--------------------------------------------------------------------------
    // Private methods

    /// @dev Computes the perp mint amount for given amount of tranche tokens deposited into the reserve.
    function _computeMintAmt(ITranche trancheIn, uint256 trancheInAmt) private view returns (uint256) {
        uint256 totalSupply_ = totalSupply();
        uint256 stdTrancheInAmt = _toStdTrancheAmt(trancheInAmt, computeDiscount(trancheIn));
        uint256 trancheInPrice = computePrice(trancheIn);
        uint256 perpAmtMint = (totalSupply_ > 0)
            ? (stdTrancheInAmt * trancheInPrice * totalSupply_) / _reserveValue()
            : (stdTrancheInAmt * trancheInPrice) / UNIT_PRICE;
        return (perpAmtMint);
    }

    /// @dev Computes the reserve token amounts redeemed when a given number of perps are burnt.
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
            redemptionAmts[i] = (totalSupply_ > 0)
                ? (_reserveBalance(reserveTokens[i]) * perpAmtBurnt) / totalSupply_
                : 0;
        }
        return (reserveTokens, redemptionAmts);
    }

    /// @dev Computes the amount of reserve tokens that can be rolled out for the given amount of tranches deposited.
    function _computeRolloverAmt(
        ITranche trancheIn,
        IERC20Upgradeable tokenOut,
        uint256 trancheInAmtAvailable,
        uint256 tokenOutAmtRequested
    ) private view returns (IPerpetualTranche.RolloverPreview memory) {
        IPerpetualTranche.RolloverPreview memory r;

        uint256 trancheInDiscount = computeDiscount(trancheIn);
        uint256 trancheOutDiscount = computeDiscount(tokenOut);
        uint256 trancheInPrice = computePrice(trancheIn);
        uint256 trancheOutPrice = computePrice(tokenOut);
        uint256 tokenOutBalance = _reserveBalance(tokenOut);
        tokenOutAmtRequested = MathUpgradeable.min(tokenOutAmtRequested, tokenOutBalance);

        if (trancheInDiscount == 0 || trancheOutDiscount == 0 || trancheInPrice == 0 || trancheOutPrice == 0) {
            r.remainingTrancheInAmt = trancheInAmtAvailable;
            return r;
        }

        r.trancheInAmt = trancheInAmtAvailable;
        uint256 stdTrancheInAmt = _toStdTrancheAmt(trancheInAmtAvailable, trancheInDiscount);

        // Basic rollover:
        // (stdTrancheInAmt . trancheInPrice) = (stdTrancheOutAmt . trancheOutPrice)
        uint256 stdTrancheOutAmt = (stdTrancheInAmt * trancheInPrice) / trancheOutPrice;
        r.trancheOutAmt = _fromStdTrancheAmt(stdTrancheOutAmt, trancheOutDiscount);

        // However, if the tokenOut is the mature tranche (held as naked collateral),
        // we infer the tokenOut amount from the tranche denomination.
        // (tokenOutAmt = collateralBalance * trancheOutAmt / matureTrancheBalance)
        bool isMatureTrancheOut = _isMatureTranche(tokenOut);
        r.tokenOutAmt = isMatureTrancheOut
            ? ((tokenOutBalance * r.trancheOutAmt) / _matureTrancheBalance)
            : r.trancheOutAmt;

        // When the token out balance is NOT covered:
        // we fix tokenOutAmt = tokenOutAmtRequested and back calculate other values
        if (r.tokenOutAmt > tokenOutAmtRequested) {
            r.tokenOutAmt = tokenOutAmtRequested;
            r.trancheOutAmt = isMatureTrancheOut
                ? (_matureTrancheBalance * r.tokenOutAmt) / tokenOutBalance
                : r.tokenOutAmt;
            stdTrancheOutAmt = _toStdTrancheAmt(r.trancheOutAmt, trancheOutDiscount);
            stdTrancheInAmt = (stdTrancheOutAmt * trancheOutPrice) / trancheInPrice;
            r.trancheInAmt = _fromStdTrancheAmt(stdTrancheInAmt, trancheInDiscount);
        }

        r.perpRolloverAmt = (stdTrancheOutAmt * trancheOutPrice * totalSupply()) / _reserveValue();
        r.remainingTrancheInAmt = trancheInAmtAvailable - r.trancheInAmt;
        return r;
    }

    /// @dev Transfers tokens from the given address to self and updates the reserve list.
    /// @return Reserve's token balance after transfer in.
    function _transferIntoReserve(
        address from,
        IERC20Upgradeable token,
        uint256 trancheAmt
    ) private returns (uint256) {
        token.safeTransferFrom(from, reserve(), trancheAmt);
        return _syncReserve(token);
    }

    /// @dev Transfers tokens from self into the given address and updates the reserve list.
    /// @return Reserve's token balance after transfer out.
    function _transferOutOfReserve(
        address to,
        IERC20Upgradeable token,
        uint256 tokenAmt
    ) private returns (uint256) {
        token.safeTransfer(to, tokenAmt);
        return _syncReserve(token);
    }

    /// @dev Keeps the reserve storage up to date. Logs the token balance held by the reserve.
    /// @return The Reserve's token balance.
    function _syncReserve(IERC20Upgradeable token) private returns (uint256) {
        uint256 balance = _reserveBalance(token);
        emit ReserveSynced(token, balance);

        // If token is the mature tranche,
        // it NEVER gets removed from the `_reserves` list.
        if (_isMatureTranche(token)) {
            return balance;
        }

        // Otherwise `_reserves` list gets updated.
        bool inReserve_ = _inReserve(token);
        if (balance > 0 && !inReserve_) {
            // Inserts new tranche into reserve list.
            _reserves.add(address(token));

            // Stores the discount for future usage.
            _applyDiscount(token, computeDiscount(token));
        }

        if (balance == 0 && inReserve_) {
            // Removes tranche from reserve list.
            _reserves.remove(address(token));

            // Frees up stored discount.
            _applyDiscount(token, 0);

            // Frees up minted supply.
            delete mintedSupplyPerTranche[ITranche(address(token))];
        }

        return balance;
    }

    /// @dev Handles fee transfer between the payer, the reserve and the protocol fee collector.
    function _settleFee(
        address payer,
        int256 reserveFee,
        uint256 protocolFee
    ) private {
        // Handling reserve fees
        uint256 reserveFeeAbs = SignedMathUpgradeable.abs(reserveFee);
        if (reserveFee > 0) {
            _handleFeeTransferIn(payer, reserve(), reserveFeeAbs);
        } else if (reserveFee < 0) {
            _handleFeeTransferOut(payer, reserveFeeAbs);
        }
        // Handling protocol fees
        if (protocolFee > 0) {
            _handleFeeTransferIn(payer, protocolFeeCollector(), protocolFee);
        }
    }

    /// @dev Transfers fee tokens from the payer to the destination.
    function _handleFeeTransferIn(
        address payer,
        address destination,
        uint256 feeAmt
    ) private {
        IERC20Upgradeable feeToken_ = feeToken();
        bool isNativeFeeToken = (feeToken_ == perpERC20());
        // Funds are coming in
        if (isNativeFeeToken) {
            // Handling a special case, when the fee is to be charged as the perp token itself
            // In this case we don't need to make an external call to the token ERC-20 to "transferFrom"
            // the payer, since this is still an internal call {msg.sender} will still point to the payer
            // and we can just "transfer" from the payer's wallet.
            transfer(destination, feeAmt);
        } else {
            feeToken_.safeTransferFrom(payer, destination, feeAmt);
        }
    }

    /// @dev Transfers fee from the reserve to the destination.
    function _handleFeeTransferOut(address destination, uint256 feeAmt) private {
        IERC20Upgradeable feeToken_ = feeToken();
        bool isNativeFeeToken = (feeToken_ == perpERC20());
        // Funds are going out
        if (isNativeFeeToken) {
            uint256 balance = _reserveBalance(feeToken_);
            feeToken_.safeTransfer(destination, MathUpgradeable.min(feeAmt, balance));

            // In case that the reserve's balance doesn't cover the entire fee amount,
            // we mint perps to cover the difference.
            if (balance < feeAmt) {
                _mint(destination, feeAmt - balance);
            }
        } else {
            feeToken_.safeTransfer(destination, feeAmt);
        }
    }

    /// @dev Updates contract store with provided discount.
    function _applyDiscount(IERC20Upgradeable token, uint256 discount) private {
        if (discount > 0) {
            _appliedDiscounts[token] = discount;
        } else {
            delete _appliedDiscounts[token];
        }
        emit DiscountApplied(token, discount);
    }

    /// @dev Updates the mature tranche balance in storage.
    function _updateMatureTrancheBalance(uint256 matureTrancheBalance) private {
        _matureTrancheBalance = matureTrancheBalance;
        emit UpdatedMatureTrancheBalance(matureTrancheBalance);
    }

    /// @dev Checks if the given token pair is a valid rollover.
    ///      * When rolling out mature tranche,
    ///          - expects incoming tranche to be part of the deposit bond
    ///      * When rolling out immature tranches,
    ///          - expects incoming tranche to be part of the deposit bond
    ///          - expects outgoing tranche to NOT be part of the deposit bond, (ie bondIn != bondOut)
    ///          - expects outgoing tranche to be in the reserve
    ///          - expects outgoing bond to NOT be "acceptable" any more
    function _isAcceptableRollover(ITranche trancheIn, IERC20Upgradeable tokenOut) private view returns (bool) {
        // when rolling out the mature tranche
        if (_isMatureTranche(tokenOut)) {
            return _isBondTranche(trancheIn, _depositBond);
        }

        // when rolling out a normal tranche
        ITranche trancheOut = ITranche(address(tokenOut));
        IBondController bondOut = IBondController(trancheOut.bond());
        return (_isBondTranche(trancheIn, _depositBond) &&
            !_isBondTranche(trancheOut, _depositBond) &&
            _inReserve(trancheOut) &&
            !_isAcceptableForReserve(bondOut));
    }

    /// @dev Checks if the bond's tranches can be accepted into the reserve.
    ///      * Expects the bond to to have the same collateral token as perp.
    ///      * Expects the bond's maturity to be within expected bounds.
    /// @return True if the bond is "acceptable".
    function _isAcceptableForReserve(IBondController bond) private view returns (bool) {
        // NOTE: `timeToMaturity` will be 0 if the bond is past maturity.
        uint256 timeToMaturity = bond.timeToMaturity();
        return (address(_reserveAt(0)) == bond.collateralToken() &&
            timeToMaturity >= minTrancheMaturitySec &&
            timeToMaturity < maxTrancheMaturitySec);
    }

    /// @dev Checks if the given tranche is a valid child of the given parent bond.
    /// @return True if the bond is the tranche's parent.
    function _isBondTranche(ITranche tranche, IBondController bond) private view returns (bool) {
        return (bond.trancheTokenAddresses(tranche) && address(bond) == tranche.bond());
    }

    /// @dev Enforces the total supply cap. To be invoked AFTER the mint operation.
    function _enforceTotalSupplyCap() private view {
        // checks if new total supply is within the max supply cap
        uint256 newSupply = totalSupply();
        if (newSupply > maxSupply) {
            revert ExceededMaxSupply(newSupply, maxSupply);
        }
    }

    /// @dev Enforces the per tranche supply cap. To be invoked AFTER the mint operation.
    function _enforcePerTrancheSupplyCap(ITranche trancheIn) private view {
        // checks if supply minted using the given tranche is within the cap
        if (mintedSupplyPerTranche[trancheIn] > maxMintAmtPerTranche) {
            revert ExceededMaxMintPerTranche(trancheIn, mintedSupplyPerTranche[trancheIn], maxMintAmtPerTranche);
        }
    }

    /// @dev Enforces that supply strictly reduces after the redemption.
    function _enforceSupplyReduction(uint256 prevSupply) private view {
        uint256 newSupply = totalSupply();
        if (newSupply >= prevSupply) {
            revert ExpectedSupplyReduction(newSupply, prevSupply);
        }
    }

    /// @dev Enforces that the percentage of the reserve value is within the target percentage.
    ///      To be invoked AFTER the rollover operation.
    function _enforceMatureValueTarget() private view {
        uint256 matureValue = (_matureTrancheBalance * computePrice(_reserveAt(0)));
        uint256 matureValuePerc = (matureValue * HUNDRED_PERC) / _reserveValue();
        if (matureValuePerc < matureValueTargetPerc) {
            revert BelowMatureValueTargetPerc(matureValuePerc, matureValueTargetPerc);
        }
    }

    /// @dev Counts the number of tokens currently in the reserve.
    function _reserveCount() private view returns (uint256) {
        return _reserves.length();
    }

    /// @dev Fetches the reserve token by index.
    function _reserveAt(uint256 i) private view returns (IERC20Upgradeable) {
        return IERC20Upgradeable(_reserves.at(i));
    }

    /// @dev Checks if the given token is in the reserve.
    function _inReserve(IERC20Upgradeable token) private view returns (bool) {
        return _reserves.contains(address(token));
    }

    /// @dev Calculates the total value of all the tranches in the reserve.
    ///      Value of each reserve tranche is calculated as = (trancheDiscount . trancheBalance) . tranchePrice.
    function _reserveValue() private view returns (uint256) {
        // For the mature tranche we use the "virtual" tranche balance
        uint256 totalVal = (_matureTrancheBalance * computePrice(_reserveAt(0)));

        // For normal tranches we use the tranche token balance
        for (uint256 i = 1; i < _reserveCount(); i++) {
            IERC20Upgradeable token = _reserveAt(i);
            uint256 stdTrancheBalance = _toStdTrancheAmt(_reserveBalance(token), computeDiscount(token));
            totalVal += (stdTrancheBalance * computePrice(token));
        }

        return totalVal;
    }

    /// @dev Checks if the given token is the mature tranche, ie) the underlying collateral token.
    function _isMatureTranche(IERC20Upgradeable token) private view returns (bool) {
        return (token == _reserveAt(0));
    }

    /// @dev Fetches the reserve's token balance.
    function _reserveBalance(IERC20Upgradeable token) private view returns (uint256) {
        return token.balanceOf(reserve());
    }

    /// @dev Calculates the standardized tranche amount for internal book keeping.
    ///      stdTrancheAmt = (trancheAmt * discount).
    function _toStdTrancheAmt(uint256 trancheAmt, uint256 discount) private pure returns (uint256) {
        return ((trancheAmt * discount) / UNIT_DISCOUNT);
    }

    /// @dev Calculates the external tranche amount from the internal standardized tranche amount.
    ///      trancheAmt = stdTrancheAmt / discount.
    function _fromStdTrancheAmt(uint256 stdTrancheAmt, uint256 discount) private pure returns (uint256) {
        return ((stdTrancheAmt * UNIT_DISCOUNT) / discount);
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20Upgradeable.sol";
import "../../../utils/ContextUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20BurnableUpgradeable is Initializable, ContextUpgradeable, ERC20Upgradeable {
    function __ERC20Burnable_init() internal onlyInitializing {
    }

    function __ERC20Burnable_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
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

    function safePermit(
        IERC20PermitUpgradeable token,
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

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

/**
 *  @title TrancheDataHelpers
 *
 *  @notice Library with helper functions the bond's retrieved tranche data.
 *
 */
library TrancheDataHelpers {
    /// @notice Iterates through the tranche data to find the seniority index of the given tranche.
    /// @param td The tranche data object.
    /// @param t The address of the tranche to check.
    /// @return the index of the tranche in the tranches array.
    function getTrancheIndex(TrancheData memory td, ITranche t) internal pure returns (uint256) {
        for (uint8 i = 0; i < td.trancheCount; i++) {
            if (td.tranches[i] == t) {
                return i;
            }
        }
        revert UnacceptableTrancheIndex(t);
    }
}

/**
 *  @title TrancheHelpers
 *
 *  @notice Library with helper functions tranche tokens.
 *
 */
library TrancheHelpers {
    /// @notice Given a tranche, looks up the collateral balance backing the tranche supply.
    /// @param t Address of the tranche token.
    /// @return The collateral balance and the tranche token supply.
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

/**
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

    /// @notice Given a bond, calculates the time remaining to maturity.
    /// @param b The address of the bond contract.
    /// @return The number of seconds before the bond reaches maturity.
    function timeToMaturity(IBondController b) internal view returns (uint256) {
        uint256 maturityDate = b.maturityDate();
        return maturityDate > block.timestamp ? maturityDate - block.timestamp : 0;
    }

    /// @notice Given a bond, calculates the bond duration i.e)
    ///         difference between creation time and maturity time.
    /// @param b The address of the bond contract.
    /// @return The duration in seconds.
    function duration(IBondController b) internal view returns (uint256) {
        return b.maturityDate() - b.creationDate();
    }

    /// @notice Given a bond, retrieves all of the bond's tranche related data.
    /// @param b The address of the bond contract.
    /// @return The tranche data.
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

    /// @notice Helper function to estimate the amount of tranches minted when a given amount of collateral
    ///         is deposited into the bond.
    /// @dev This function is used off-chain services (using callStatic) to preview tranches minted after
    /// @param b The address of the bond contract.
    /// @return The tranche data, an array of tranche amounts and fees.
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

    /// @notice Given a bond, for each tranche token retrieves the total collateral redeemable
    ///         for the total supply of the tranche token (aka debt issued).
    /// @dev The cdr can be computed for each tranche by dividing the
    ///      returned tranche's collateralBalance by the tranche's totalSupply.
    /// @param b The address of the bond contract.
    /// @return The tranche data and the list of collateral balances and the total supplies for each tranche.
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

    /// @notice Given a bond, retrieves the collateral redeemable for
    ///         each tranche held by the given address.
    /// @param b The address of the bond contract.
    /// @param u The address to check balance for.
    /// @return The tranche data and an array of collateral balances.
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

import { IBondIssuer } from "./IBondIssuer.sol";
import { IFeeStrategy } from "./IFeeStrategy.sol";
import { IPricingStrategy } from "./IPricingStrategy.sol";
import { IDiscountStrategy } from "./IDiscountStrategy.sol";
import { IBondController } from "./buttonwood/IBondController.sol";
import { ITranche } from "./buttonwood/ITranche.sol";

interface IPerpetualTranche is IERC20Upgradeable {
    //--------------------------------------------------------------------------
    // Events

    /// @notice Event emitted when the keeper is updated.
    /// @param prevKeeper The address of the previous keeper.
    /// @param newKeeper The address of the new keeper.
    event UpdatedKeeper(address prevKeeper, address newKeeper);

    /// @notice Event emitted when the bond issuer is updated.
    /// @param issuer Address of the issuer contract.
    event UpdatedBondIssuer(IBondIssuer issuer);

    /// @notice Event emitted when the fee strategy is updated.
    /// @param strategy Address of the strategy contract.
    event UpdatedFeeStrategy(IFeeStrategy strategy);

    /// @notice Event emitted when the pricing strategy is updated.
    /// @param strategy Address of the strategy contract.
    event UpdatedPricingStrategy(IPricingStrategy strategy);

    /// @notice Event emitted when the discount strategy is updated.
    /// @param strategy Address of the strategy contract.
    event UpdatedDiscountStrategy(IDiscountStrategy strategy);

    /// @notice Event emitted when maturity tolerance parameters are updated.
    /// @param min The minimum maturity time.
    /// @param max The maximum maturity time.
    event UpdatedTolerableTrancheMaturity(uint256 min, uint256 max);

    /// @notice Event emitted when the supply caps are updated.
    /// @param maxSupply The max total supply.
    /// @param maxMintAmtPerTranche The max mint amount per tranche.
    event UpdatedMintingLimits(uint256 maxSupply, uint256 maxMintAmtPerTranche);

    /// @notice Event emitted when the mature value target percentage is updated.
    /// @param matureValueTargetPerc The new target percentage.
    event UpdatedMatureValueTargetPerc(uint256 matureValueTargetPerc);

    /// @notice Event emitted when the applied discount for a given token is set.
    /// @param token The address of the token.
    /// @param discount The discount factor applied.
    event DiscountApplied(IERC20Upgradeable token, uint256 discount);

    /// @notice Event emitted the reserve's current token balance is recorded after change.
    /// @param token Address of token.
    /// @param balance The recorded ERC-20 balance of the token held by the reserve.
    event ReserveSynced(IERC20Upgradeable token, uint256 balance);

    /// @notice Event emitted when the active deposit bond is updated.
    /// @param bond Address of the new deposit bond.
    event UpdatedDepositBond(IBondController bond);

    /// @notice Event emitted when the mature tranche balance is updated.
    /// @param matureTrancheBalance The mature tranche balance.
    event UpdatedMatureTrancheBalance(uint256 matureTrancheBalance);

    //--------------------------------------------------------------------------
    // Methods

    /// @notice Deposits tranche tokens into the system and mint perp tokens.
    /// @param trancheIn The address of the tranche token to be deposited.
    /// @param trancheInAmt The amount of tranche tokens deposited.
    function deposit(ITranche trancheIn, uint256 trancheInAmt) external;

    /// @notice Burn perp tokens and redeem the share of reserve assets.
    /// @param perpAmtBurnt The amount of perp tokens burnt from the caller.
    function redeem(uint256 perpAmtBurnt) external;

    /// @notice Rotates newer tranches in for reserve tokens.
    /// @param trancheIn The tranche token deposited.
    /// @param tokenOut The reserve token to be redeemed.
    /// @param trancheInAmt The amount of trancheIn tokens deposited.
    function rollover(
        ITranche trancheIn,
        IERC20Upgradeable tokenOut,
        uint256 trancheInAmt
    ) external;

    /// @notice Reference to the wallet or contract that has the ability to pause/unpause operations.
    /// @return The address of the keeper.
    function keeper() external view returns (address);

    /// @notice The address of the underlying rebasing ERC-20 collateral token backing the tranches.
    /// @return Address of the collateral token.
    function collateral() external view returns (IERC20Upgradeable);

    /// @notice The "virtual" balance of all mature tranches held by the system.
    /// @return The mature tranche balance.
    function getMatureTrancheBalance() external returns (uint256);

    /// @notice The parent bond whose tranches are currently accepted to mint perp tokens.
    /// @return Address of the deposit bond.
    function getDepositBond() external returns (IBondController);

    /// @notice Checks if the given `trancheIn` can be rolled out for `tokenOut`.
    /// @param trancheIn The tranche token deposited.
    /// @param tokenOut The reserve token to be redeemed.
    function isAcceptableRollover(ITranche trancheIn, IERC20Upgradeable tokenOut) external returns (bool);

    /// @notice The strategy contract with the fee computation logic.
    /// @return Address of the strategy contract.
    function feeStrategy() external view returns (IFeeStrategy);

    /// @notice The ERC-20 contract which holds perp balances.
    /// @return Address of the token.
    function perpERC20() external view returns (IERC20Upgradeable);

    /// @notice The contract where the protocol holds funds which back the perp token supply.
    /// @return Address of the reserve.
    function reserve() external view returns (address);

    /// @notice The address which holds any revenue extracted by protocol.
    /// @return Address of the fee collector.
    function protocolFeeCollector() external view returns (address);

    /// @notice The fee token currently used to receive fees in.
    /// @return Address of the fee token.
    function feeToken() external view returns (IERC20Upgradeable);

    /// @notice Total count of tokens held in the reserve.
    function getReserveCount() external returns (uint256);

    /// @notice The token address from the reserve list by index.
    /// @param index The index of a token.
    function getReserveAt(uint256 index) external returns (IERC20Upgradeable);

    /// @notice Checks if the given token is part of the reserve.
    /// @param token The address of a token to check.
    function inReserve(IERC20Upgradeable token) external returns (bool);

    /// @notice Fetches the reserve's tranche token balance.
    /// @param tranche The address of the tranche token held by the reserve.
    function getReserveTrancheBalance(IERC20Upgradeable tranche) external returns (uint256);

    /// @notice Computes the price of each perp token, i.e) reserve value / total supply.
    function getAvgPrice() external returns (uint256);

    /// @notice Fetches the list of reserve tokens which are up for rollover.
    function getReserveTokensUpForRollover() external returns (IERC20Upgradeable[] memory);

    /// @notice Computes the amount of perp tokens minted when `trancheInAmt` `trancheIn` tokens
    ///         are deposited into the system.
    /// @param trancheIn The tranche token deposited.
    /// @param trancheInAmt The amount of tranche tokens deposited.
    /// @return The amount of perp tokens to be minted.
    function computeMintAmt(ITranche trancheIn, uint256 trancheInAmt) external returns (uint256);

    /// @notice Computes the amount reserve tokens redeemed when burning given number of perp tokens.
    /// @param perpAmtBurnt The amount of perp tokens to be burnt.
    /// @return tokensOut The list of reserve tokens redeemed.
    /// @return tokenOutAmts The list of reserve token amounts redeemed.
    function computeRedemptionAmts(uint256 perpAmtBurnt)
        external
        returns (IERC20Upgradeable[] memory tokensOut, uint256[] memory tokenOutAmts);

    struct RolloverPreview {
        /// @notice The perp denominated value of tokens rolled over.
        uint256 perpRolloverAmt;
        /// @notice The amount of tokens rolled out.
        uint256 tokenOutAmt;
        /// @notice The tranche denominated amount of tokens rolled out.
        /// @dev tokenOutAmt and trancheOutAmt can only be different values
        ///      in the case of rolling over the mature tranche.
        uint256 trancheOutAmt;
        /// @notice The amount of trancheIn tokens rolled in.
        uint256 trancheInAmt;
        /// @notice The difference between the available trancheIn amount and
        ///        the amount of tokens used for the rollover.
        uint256 remainingTrancheInAmt;
    }

    /// @notice Computes the amount reserve tokens that are rolled out for the given number
    ///         of `trancheIn` tokens rolled in.
    /// @param trancheIn The tranche token rolled in.
    /// @param tokenOut The reserve token to be rolled out.
    /// @param trancheInAmtAvailable The amount of trancheIn tokens rolled in.
    /// @param tokenOutAmtRequested The amount of tokenOut tokens requested to be rolled out.
    /// @return r The rollover amounts in various denominations.
    function computeRolloverAmt(
        ITranche trancheIn,
        IERC20Upgradeable tokenOut,
        uint256 trancheInAmtAvailable,
        uint256 tokenOutAmtRequested
    ) external returns (RolloverPreview memory);

    /// @notice The discount to be applied given the reserve token.
    /// @param token The address of the reserve token.
    /// @return The discount applied.
    function computeDiscount(IERC20Upgradeable token) external view returns (uint256);

    /// @notice The price of the given reserve token.
    /// @param token The address of the reserve token.
    /// @return The computed price.
    function computePrice(IERC20Upgradeable token) external view returns (uint256);

    /// @notice Updates time dependent storage state.
    function updateState() external;
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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

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
     * @dev Moves `amount` of tokens from `from` to `to`.
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
interface IERC20PermitUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/SafeCast.sol)

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

    function trancheTokenAddresses(ITranche token) external view returns (bool);

    function deposit(uint256 amount) external;

    function redeem(uint256[] memory amounts) external;

    function mature() external;

    function redeemMature(address tranche, uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface ITranche is IERC20Upgradeable {
    function bond() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import { IBondController } from "./buttonwood/IBondController.sol";

interface IBondIssuer {
    /// @notice Event emitted when a new bond is issued by the issuer.
    /// @param bond The newly issued bond.
    event BondIssued(IBondController bond);

    /// @notice The address of the underlying collateral token to be used for issued bonds.
    /// @return Address of the collateral token.
    function collateral() external view returns (address);

    /// @notice Issues a new bond if sufficient time has elapsed since the last issue.
    function issue() external;

    /// @notice Checks if a given bond has been issued by the issuer.
    /// @param bond Address of the bond to check.
    /// @return if the bond has been issued by the issuer.
    function isInstance(IBondController bond) external view returns (bool);

    /// @notice Fetches the most recently issued bond.
    /// @return Address of the most recent bond.
    function getLatestBond() external returns (IBondController);

    /// @notice Returns the total number of bonds issued by this issuer.
    /// @return Number of bonds.
    function issuedCount() external view returns (uint256);

    /// @notice The bond address from the issued list by index.
    /// @return Address of the bond.
    function issuedBondAt(uint256 index) external view returns (IBondController);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IFeeStrategy {
    /// @notice Address of the fee token.
    function feeToken() external view returns (IERC20Upgradeable);

    /// @notice Computes the fees while minting given amount of perp tokens.
    /// @dev The mint fee can be either positive or negative. When positive it's paid by the minting users to the reserve.
    ///      When negative its paid to the minting users by the reserve.
    ///      The protocol fee is always non-negative and is paid by the users minting to the
    ///      perp contract's fee collector.
    /// @param amount The amount of perp tokens to be minted.
    /// @return reserveFee The fee paid to the reserve to mint perp tokens.
    /// @return protocolFee The fee paid to the protocol to mint perp tokens.
    function computeMintFees(uint256 amount) external view returns (int256 reserveFee, uint256 protocolFee);

    /// @notice Computes the fees while burning given amount of perp tokens.
    /// @dev The burn fee can be either positive or negative. When positive it's paid by the burning users to the reserve.
    ///      When negative its paid to the burning users by the reserve.
    ///      The protocol fee is always non-negative and is paid by the users burning to the
    ///      perp contract's fee collector.
    /// @param amount The amount of perp tokens to be burnt.
    /// @return reserveFee The fee paid to the reserve to burn perp tokens.
    /// @return protocolFee The fee paid to the protocol to burn perp tokens.
    function computeBurnFees(uint256 amount) external view returns (int256 reserveFee, uint256 protocolFee);

    /// @notice Computes the fees while rolling over given amount of perp tokens.
    /// @dev The rollover fee can be either positive or negative. When positive it's paid by the users rolling over to the reserve.
    ///      When negative its paid to the users rolling over by the reserve.
    ///      The protocol fee is always positive and is paid by the users rolling over to the
    ///      perp contract's fee collector.
    /// @param amount The Perp-denominated value of the tranches being rolled over.
    /// @return reserveFee The fee paid to the reserve to rollover tokens.
    /// @return protocolFee The fee paid to the protocol to rollover tokens.
    function computeRolloverFees(uint256 amount) external view returns (int256 reserveFee, uint256 protocolFee);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { ITranche } from "../_interfaces/buttonwood/ITranche.sol";

interface IPricingStrategy {
    /// @notice Computes the price of a given tranche token.
    /// @param tranche The tranche to compute price of.
    /// @return The price as a fixed point number with `decimals()`.
    function computeTranchePrice(ITranche tranche) external view returns (uint256);

    /// @notice Computes the price of mature tranches extracted and held as naked collateral.
    /// @param collateralToken The collateral token.
    /// @param collateralBalance The collateral balance of all the mature tranches.
    /// @param debt The total count of mature tranches.
    /// @return The price as a fixed point number with `decimals()`.
    function computeMatureTranchePrice(
        IERC20Upgradeable collateralToken,
        uint256 collateralBalance,
        uint256 debt
    ) external view returns (uint256);

    /// @notice Number of price decimals.
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IDiscountStrategy {
    /// @notice Computes the discount to be applied to a given tranche token.
    /// @param tranche The tranche token to compute discount for.
    /// @return The discount as a fixed point number with `decimals()`.
    function computeTrancheDiscount(IERC20Upgradeable tranche) external view returns (uint256);

    /// @notice Number of discount decimals.
    function decimals() external view returns (uint8);
}