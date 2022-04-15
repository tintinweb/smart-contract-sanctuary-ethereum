// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { SignedMath } from "@openzeppelin/contracts/utils/math/SignedMath.sol";

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import { AddressQueue, AddressQueueHelpers } from "./_utils/AddressQueueHelpers.sol";
import { TrancheData, TrancheDataHelpers, BondHelpers } from "./_utils/BondHelpers.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ITranche } from "./_interfaces/buttonwood/ITranche.sol";
import { IBondController } from "./_interfaces/buttonwood/IBondController.sol";

import { IPerpetualTranche } from "./_interfaces/IPerpetualTranche.sol";
import { IBondIssuer } from "./_interfaces/IBondIssuer.sol";
import { IFeeStrategy } from "./_interfaces/IFeeStrategy.sol";
import { IPricingStrategy } from "./_interfaces/IPricingStrategy.sol";

/*
 *  @title PerpetualTranche
 *
 *  @notice An opinionated implementation of a perpetual tranche ERC-20 token contract.
 *
 *          Perp tokens are backed by tranche tokens. Users can mint perp tokens by depositing tranches.
 *          They can redeem tranches by burning their perp tokens.
 *
 *          Users can ONLY mint perp tokens for tranches belonging to the active "deposit" bond.
 *
 *          The PerpetualTranche contract enforces tranche redemption through a FIFO queue.
 *          1) The queue is ordered by the maturity date, the tail of the queue has the newest issued tranches
 *             i.e) the one that matures furthest out into the future.
 *          2) When a user deposits a tranche belonging to the depositBond for the first time,
 *             it is added to the tail of the queue.
 *          3) When a user burns perp tokens, it iteratively redeems tranches from the head of the queue
 *             till the requested amount is covered.
 *          4) Tranches which are about to mature are removed from the tranche queue.
 *
 *          Once tranches are removed from the queue, they entire a holding area called the "icebox".
 *          Tranches in the icebox can only be redeemed when the tranche queue is empty.
 *
 *          Incentivized parties can "rollover" older tranches in the icebox for
 *          newer tranches that belong to the "depositBond".
 *
 *          At any time perp contract holds 2 classes of tokens. "reserve" tokens and "non-reserve" tokens.
 *          The system maintains a list of tokens which it considers are "reserve" tokens.
 *          The reserve tokens are the list of tranche tokens which are which back the supply of perp tokens.
 *          These reserve tokens can only leave the system on "redeem" and "rollover".
 *          Non reserve assets on the other hand can be transferred out by the contract owner if need be.
 *
 *
 */
contract PerpetualTranche is ERC20, Initializable, Ownable, IPerpetualTranche {
    using Math for uint256;
    using SafeCast for uint256;
    using SignedMath for int256;
    using SafeERC20 for IERC20;
    using SafeERC20 for ITranche;
    using EnumerableSet for EnumerableSet.AddressSet;
    using AddressQueueHelpers for AddressQueue;
    using BondHelpers for IBondController;
    using TrancheDataHelpers for TrancheData;

    //-------------------------------------------------------------------------
    // Constants & Immutables
    uint8 public constant YIELD_DECIMALS = 18;
    uint8 public constant PRICE_DECIMALS = 8;

    // @dev Number of ERC-20 decimal places to get the perp token amount for user representation.
    uint8 private immutable _decimals;

    //-------------------------------------------------------------------------
    // Data

    // @notice Issuer stores a predefined bond config and frequency and issues new bonds when poked
    // @dev Only tranches of bonds issued by the whitelisted issuer are accepted by the system.
    IBondIssuer public bondIssuer;

    // @notice External contract points to the fee token and computes mint, burn and rollover fees.
    IFeeStrategy public override feeStrategy;

    // @notice External contract that computes a given tranche's price.
    // @dev The computed price is expected to be a fixed point unsigned integer with {PRICE_DECIMALS} decimals.
    IPricingStrategy public pricingStrategy;

    // @notice A FIFO queue of tranches ordered by maturity time used to enforce redemption ordering.
    // @dev Most recently created tranches pushed to the tail of the queue (on deposit) and
    //      the oldest ones are pulled from the head of the queue (on redemption).
    AddressQueue private _redemptionQueue;

    // @notice A record of all tranches with a balance held in the reserve which backs perp token supply.
    EnumerableSet.AddressSet private _reserves;

    // TODO: allow multiple deposit bonds
    // @notice The active deposit bond of whose tranches are currently being accepted as deposits
    //         to mint perp tokens.
    IBondController private _depositBond;

    // @notice Yield factor defined for a particular "class" of tranches.
    //         Any tranche's class is defined as the unique combination of:
    //          - it's collateralToken
    //          - it's parent bond's trancheRatios
    //          - it's seniorityIDX
    //
    // @dev For example:
    //      all AMPL [35-65] bonds can be configured to have a yield of [1, 0] and
    //      all AMPL [50-50] bonds can be configured to have a yield of [0.8,0]
    //
    //      An AMPL-A tranche token from any [35-65] bond will be applied a yield factor of 1.
    //      An AMPL-A tranche token from any [50-50] bond will be applied a yield factor of 0.8.
    //
    //      The yield is specified as a fixed point unsigned integer with {YIELD_DECIMALS} decimals.
    mapping(bytes32 => uint256) private _definedTrancheYields;

    // @notice Yield factor actually "applied" on each tranche instance. It is recorded when
    //         a particular tranche token is deposited into the system for the first time.
    //
    // @dev The yield factor is computed and set when a tranche instance enters the system for the first time.
    //      For all calculations thereafter, the set factor will be used.
    //      This distinction between the "defined" and "applied" yield allows the owner to safely
    //      update tranche yields without affecting the system's collateralization ratio.
    //      The yield is stored as a fixed point unsigned integer with {YIELD_DECIMALS} decimals
    mapping(ITranche => uint256) private _appliedTrancheYields;

    // @notice The minimum maturity time in seconds for a tranche below which
    //         it can get removed from the tranche queue.
    uint256 public minTrancheMaturiySec;

    // @notice The maximum maturity time in seconds for a tranche above which
    //         it can NOT get added into the tranche queue.
    uint256 public maxTrancheMaturiySec;

    //--------------------------------------------------------------------------
    // Modifiers
    modifier afterUpdateQueue() {
        updateQueue();
        _;
    }

    //--------------------------------------------------------------------------
    // Construction & Initialization

    // @notice Constructor to create the contract.
    // @param name ERC-20 Name of the Perp token.
    // @param symbol ERC-20 Symbol of the Perp token.
    // @param decimals_ Number of ERC-20 decimal places.
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals_
    ) ERC20(name, symbol) {
        _decimals = decimals_;
    }

    // @notice Contract state initialization.
    // @param bondIssuer_ Address of the bond issuer contract.
    // @param feeStrategy_ Address of the fee strategy contract.
    // @param pricingStrategy_ Address of the pricing strategy contract.
    function init(
        IBondIssuer bondIssuer_,
        IFeeStrategy feeStrategy_,
        IPricingStrategy pricingStrategy_
    ) public initializer {
        updateBondIssuer(bondIssuer_);
        updateFeeStrategy(feeStrategy_);
        updatePricingStrategy(pricingStrategy_);

        minTrancheMaturiySec = 1;
        maxTrancheMaturiySec = type(uint256).max;

        _redemptionQueue.init();
    }

    //--------------------------------------------------------------------------
    // ADMIN only methods

    // @notice Update the reference to the bond issuer contract.
    // @param bondIssuer_ New bond issuer address.
    function updateBondIssuer(IBondIssuer bondIssuer_) public onlyOwner {
        require(address(bondIssuer_) != address(0), "Expected new bond issuer to be set");
        bondIssuer = bondIssuer_;
        emit UpdatedBondIssuer(bondIssuer_);
    }

    // @notice Update the reference to the fee strategy contract.
    // @param feeStrategy_ New strategy address.
    function updateFeeStrategy(IFeeStrategy feeStrategy_) public onlyOwner {
        require(address(feeStrategy_) != address(0), "Expected new fee strategy to be set");
        feeStrategy = feeStrategy_;
        emit UpdatedFeeStrategy(feeStrategy_);
    }

    // @notice Update the reference to the pricing strategy contract.
    // @param pricingStrategy_ New strategy address.
    function updatePricingStrategy(IPricingStrategy pricingStrategy_) public onlyOwner {
        require(address(pricingStrategy_) != address(0), "Expected new pricing strategy to be set");
        require(pricingStrategy_.decimals() == PRICE_DECIMALS, "Expected new pricing strategy to use same decimals");
        pricingStrategy = pricingStrategy_;
        emit UpdatedPricingStrategy(pricingStrategy_);
    }

    // @notice Update the maturity tolerance parameters.
    // @param minTrancheMaturiySec_ New minimum maturity time.
    // @param maxTrancheMaturiySec_ New maximum maturity time.
    // @dev NOTE: Setting `minTrancheMaturiySec` to 0 will mean bonds will remain in the queue
    //      past maturity.
    function updateTolerableTrancheMaturiy(uint256 minTrancheMaturiySec_, uint256 maxTrancheMaturiySec_)
        external
        onlyOwner
    {
        require(minTrancheMaturiySec_ <= maxTrancheMaturiySec_, "Expected max to be greater than min");
        minTrancheMaturiySec = minTrancheMaturiySec_;
        maxTrancheMaturiySec = maxTrancheMaturiySec_;
        emit UpdatedTolerableTrancheMaturiy(minTrancheMaturiySec_, maxTrancheMaturiySec_);
    }

    // @notice Updates the tranche class's yields.
    // @param classHash The tranche class (hash(collteralToken, trancheRatios, seniority)).
    // @param yields The yield factor.
    function updateDefinedYield(bytes32 classHash, uint256 yield) external onlyOwner {
        if (yield > 0) {
            _definedTrancheYields[classHash] = yield;
        } else {
            delete _definedTrancheYields[classHash];
        }
        emit UpdatedDefinedTrancheYields(classHash, yield);
    }

    // @notice Allows the owner to transfer non-reserve assets out of the system if required.
    // @param token The token address.
    // @param to The destination address.
    // @param amount The amount of tokens to be transferred.
    function transferERC20(
        IERC20 token,
        address to,
        uint256 amount
    ) external onlyOwner {
        require(!inReserve(token), "Expected token to NOT be reserve asset");
        token.safeTransfer(to, amount);
    }

    //--------------------------------------------------------------------------
    // External methods

    /// @inheritdoc IPerpetualTranche
    function deposit(ITranche trancheIn, uint256 trancheInAmt)
        external
        override
        afterUpdateQueue
        returns (uint256 mintAmt, int256 mintFee)
    {
        require(_depositBond == IBondController(trancheIn.bond()), "Expected tranche to be of deposit bond");

        // calculates the amount of perp tokens the `trancheInAmt` of tranche tokens are worth
        mintAmt = tranchesToPerps(trancheIn, trancheInAmt);
        require(mintAmt > 0 && trancheInAmt > 0, "Expected to mint a non-zero amount of tokens");

        // calculates the fee to mint `mintAmt` of perp token
        mintFee = feeStrategy.computeMintFee(mintAmt);

        // Handles tranche transfer in
        {
            // transfers deposited tranches from the sender to the reserve
            _transferIntoReserve(_msgSender(), trancheIn, trancheInAmt);

            // NOTE: Enqueues tranche if this is the first time the tranche token
            // is entering the system
            _checkAndEnqueueTranche(trancheIn);
        }

        // Handles perp and fee transfer
        {
            // mints perp tokens to the sender
            _mint(_msgSender(), mintAmt);

            // settles fees
            bool isNativeFeeToken = _settleFee(_msgSender(), mintFee);

            // When the fee is charged in the native token,
            // fee has been withheld from the mint amount.
            // Adjusting the return value to account for this.
            if (isNativeFeeToken) {
                mintAmt = (mintAmt.toInt256() - mintFee).abs();
            }
        }

        return (mintAmt, mintFee);
    }

    /// @inheritdoc IPerpetualTranche
    function redeem(ITranche trancheOut, uint256 perpAmountRequested)
        external
        override
        afterUpdateQueue
        returns (uint256 burnAmt, int256 burnFee)
    {
        ITranche redemptionTranche = _redemptionTranche();

        // When tranche queue is NOT empty, redemption ordering is enforced.
        bool inOrderRedemption = address(redemptionTranche) != address(0);

        // The system only allows redemption of the burning tranche for perp tokens
        // i.e) the tranche at the head of the tranche queue.
        // When the queue is empty, any tranche held in the reserve can be redeemed.
        require(
            trancheOut == redemptionTranche || !inOrderRedemption,
            "Expected to redeem burning tranche or queue to be empty"
        );

        // calculates the amount of tranche tokens covered to burn `remainder` perp tokens
        (uint256 trancheOutAmt, uint256 remainder) = perpsToCoveredTranches(trancheOut, perpAmountRequested);
        require(perpAmountRequested > 0 && trancheOutAmt > 0, "Expected to burn a non-zero amount of tokens");

        // calculates the covered burn amount
        burnAmt = perpAmountRequested - remainder;

        // calculates the fee to burn `burnAmt` of perp token
        burnFee = feeStrategy.computeBurnFee(burnAmt);

        // Handles perp and fee transfer
        {
            // burns perp tokens from the sender
            _burn(_msgSender(), burnAmt);

            // settles fees
            _settleFee(_msgSender(), burnFee);
        }

        // Handles tranche transfer out
        {
            // transfers redeemed tranches from the reserve to the sender
            uint256 reserveBalance = _transferOutOfReserve(_msgSender(), trancheOut, trancheOutAmt);

            // NOTE: When redeeming in order and if the tranche balance was burnt fully,
            //       Dequeuing the tranche.
            if (inOrderRedemption && reserveBalance == 0) {
                _dequeueTranche();
            }
        }

        return (burnAmt, burnFee);
    }

    /// @inheritdoc IPerpetualTranche
    // @dev This will revert if the trancheOutAmt isn't covered.
    function rollover(
        ITranche trancheIn,
        ITranche trancheOut,
        uint256 trancheInAmt
    ) external override afterUpdateQueue returns (uint256 trancheOutAmt, int256 rolloverFee) {
        require(_isAcceptableRollover(trancheIn, trancheOut), "Expected rolling over tranches into the queue");

        // calculates the perp denominated amount rolled over
        uint256 rolloverAmt = tranchesToPerps(trancheIn, trancheInAmt);

        // calculates the amount of tranche tokens rolled out
        trancheOutAmt = perpsToTranches(trancheOut, rolloverAmt);
        require(rolloverAmt > 0 && trancheOutAmt > 0, "Expected to rollover a non-zero amount of tokens");

        // calculates the fee to rollover `rolloverAmt` of perp token
        rolloverFee = feeStrategy.computeRolloverFee(rolloverAmt);

        // Handles tranche transfer in
        {
            // transfers tranche tokens from the sender to the reserve
            _transferIntoReserve(_msgSender(), trancheIn, trancheInAmt);

            // NOTE: Enqueues tranche if this is the first time the tranche token
            // is entering the system
            _checkAndEnqueueTranche(trancheIn);
        }

        // Handles tranche transfer out and fee transfer
        {
            // transfers tranche tokens from the reserve to the sender
            _transferOutOfReserve(_msgSender(), trancheOut, trancheOutAmt);

            // settles fees
            _settleFee(_msgSender(), rolloverFee);
        }

        return (trancheOutAmt, rolloverFee);
    }

    /// @inheritdoc IPerpetualTranche
    // @dev Used in case an altruistic party intends to increase the collaterlization ratio.
    function burn(uint256 amount) external override returns (bool) {
        _burn(_msgSender(), amount);
        return true;
    }

    /// @inheritdoc IPerpetualTranche
    function getDepositBond() external override afterUpdateQueue returns (IBondController) {
        return _depositBond;
    }

    /// @inheritdoc IPerpetualTranche
    function getRedemptionTranche() external override afterUpdateQueue returns (ITranche tranche) {
        return _redemptionTranche();
    }

    /// @inheritdoc IPerpetualTranche
    // @dev Lazily updates the queue before fetching from storage.
    function getRedemptionQueueCount() external override afterUpdateQueue returns (uint256) {
        return _redemptionQueue.length();
    }

    /// @inheritdoc IPerpetualTranche
    // @dev Lazily updates the queue before fetching from storage.
    function getRedemptionQueueAt(uint256 i) external override afterUpdateQueue returns (address) {
        return _redemptionQueue.at(i);
    }

    /// @inheritdoc IPerpetualTranche
    // @dev Lazily updates the queue before verifying state.
    function isAcceptableRollover(ITranche trancheIn, ITranche trancheOut)
        external
        override
        afterUpdateQueue
        returns (bool)
    {
        return _isAcceptableRollover(trancheIn, trancheOut);
    }

    //--------------------------------------------------------------------------
    // Public methods

    /// @inheritdoc IPerpetualTranche
    // @dev Lazily updates time-dependent queue state.
    //      This function is to be invoked on all external function entry points which are
    //      read data from the queue.
    function updateQueue() public override {
        // Lazily queries the bond issuer to get the most recently issued bond
        // and updates with the new deposit bond if it's "acceptable".
        {
            IBondController newBond = bondIssuer.getLatestBond();
            // new bond has been issued by the issuer and is "acceptable"
            // update `_depositBond`
            if (_depositBond != newBond && _isAcceptable(newBond)) {
                _depositBond = newBond;
            }
        }

        // Lazily dequeues tranches from the tranche queue till the head of the
        // queue is an "acceptable" tranche.
        {
            ITranche redemptionTranche = _redemptionTranche();
            while (
                address(redemptionTranche) != address(0) && !_isAcceptable(IBondController(redemptionTranche.bond()))
            ) {
                _dequeueTranche();
                redemptionTranche = _redemptionTranche();
            }
        }
    }

    //--------------------------------------------------------------------------
    // External view methods

    /// @inheritdoc IPerpetualTranche
    function reserveCount() external view override returns (uint256) {
        return _reserves.length();
    }

    /// @inheritdoc IPerpetualTranche
    function reserveAt(uint256 i) external view override returns (address) {
        return _reserves.at(i);
    }

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
    function feeToken() public view override returns (IERC20) {
        return feeStrategy.feeToken();
    }

    /// @inheritdoc IPerpetualTranche
    function inReserve(IERC20 token) public view override returns (bool) {
        return _reserves.contains(address(token));
    }

    /// @inheritdoc IPerpetualTranche
    // @dev Gets the applied yield for the given tranche if it's set set,
    //      if NOT gets the defined tranche yield
    function trancheYield(ITranche t) public view override returns (uint256) {
        uint256 yield = _appliedTrancheYields[t];
        return yield > 0 ? yield : _definedTrancheYields[trancheClass(t)];
    }

    /// @inheritdoc IPerpetualTranche
    // @dev A given tranche's computed class is the
    //      hash(collteralToken, trancheRatios, seniority).
    function trancheClass(ITranche t) public view override returns (bytes32) {
        IBondController bond = IBondController(t.bond());
        TrancheData memory td = bond.getTrancheData();
        return keccak256(abi.encode(bond.collateralToken(), td.trancheRatios, td.getTrancheIndex(t)));
    }

    /// @inheritdoc IPerpetualTranche
    function tranchePrice(ITranche t) public view override returns (uint256) {
        return pricingStrategy.computeTranchePrice(t);
    }

    /// @inheritdoc IPerpetualTranche
    function tranchesToPerps(ITranche t, uint256 trancheAmt) public view override returns (uint256) {
        return _tranchesToPerps(trancheAmt, trancheYield(t), tranchePrice(t));
    }

    /// @inheritdoc IPerpetualTranche
    function perpsToTranches(ITranche t, uint256 amount) public view override returns (uint256) {
        return _perpsToTranches(amount, trancheYield(t), tranchePrice(t));
    }

    /// @inheritdoc IPerpetualTranche
    function perpsToCoveredTranches(ITranche t, uint256 perpAmountRequested)
        public
        view
        override
        returns (uint256, uint256)
    {
        return _perpsToCoveredTranches(t, perpAmountRequested, trancheYield(t), tranchePrice(t));
    }

    // @notice Returns the number of decimals used to get its user representation.
    // @dev For example, if `decimals` equals `2`, a balance of `505` tokens should
    //      be displayed to a user as `5.05` (`505 / 10 ** 2`).
    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    //--------------------------------------------------------------------------
    // Private/Internal helper methods

    // @dev If the given tranche isn't already part of the tranche queue,
    //      it is added to the tail of the queue and its yield factor is set.
    //      This is invoked when the tranche enters the system for the first time on deposit.
    function _checkAndEnqueueTranche(ITranche t) internal {
        if (!_redemptionQueue.contains(address(t))) {
            // Inserts new tranche into tranche queue
            _redemptionQueue.enqueue(address(t));
            emit TrancheEnqueued(t);

            // Stores the yield for future usage.
            uint256 yield = trancheYield(t);
            _appliedTrancheYields[t] = yield;
            emit TrancheYieldApplied(t, yield);
        }
    }

    // @dev Removes the tranche from the head of the queue.
    function _dequeueTranche() internal {
        emit TrancheDequeued(ITranche(_redemptionQueue.dequeue()));
    }

    // @dev The head of the tranche queue which is up for redemption next.
    function _redemptionTranche() internal returns (ITranche) {
        return ITranche(_redemptionQueue.head());
    }

    // @dev Checks if the given tranche pair is a valid rollover.
    function _isAcceptableRollover(ITranche trancheIn, ITranche trancheOut) internal returns (bool) {
        IBondController bondIn = IBondController(trancheIn.bond());
        IBondController bondOut = IBondController(trancheOut.bond());
        return (bondIn != bondOut && // Expected bondIn and bondOut NOT be the same
            bondIn == _depositBond && // Expected trancheIn to be of deposit bond
            !_redemptionQueue.contains(address(trancheOut))); // Expected trancheOut to not be part of the queue
    }

    // @dev If the fee is positive, fee is transferred from the payer to the self
    //      else it's transferred to the payer from the self.
    //      NOTE: fee is a not-reserve asset.
    // @return True if the fee token used for settlement is the perp token.
    function _settleFee(address payer, int256 fee) internal returns (bool isNativeFeeToken) {
        IERC20 feeToken_ = feeToken();
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

    // @dev Transfers tokens from the given address to self and updates the reserve list.
    // @return Reserve balance after transfer in.
    function _transferIntoReserve(
        address from,
        IERC20 token,
        uint256 amount
    ) internal returns (uint256) {
        token.safeTransferFrom(from, _self(), amount);
        return _syncReserves(token);
    }

    // @dev Transfers tokens from self into the given address and updates the reserve list.
    // @return Reserve balance after transfer out.
    function _transferOutOfReserve(
        address to,
        IERC20 token,
        uint256 amount
    ) internal returns (uint256) {
        token.safeTransfer(to, amount);
        return _syncReserves(token);
    }

    // @dev Keeps the list of tokens held in the reserve up to date.
    //      Perp tokens are backed by tokens in this list.
    // @return The reserve's token balance
    function _syncReserves(IERC20 t) internal returns (uint256) {
        uint256 balance = t.balanceOf(_self());
        bool inReserve_ = inReserve(t);
        if (balance > 0 && !inReserve_) {
            _reserves.add(address(t));
        } else if (balance == 0 && inReserve_) {
            _reserves.remove(address(t));
        }
        emit ReserveSynced(t, balance);
        return balance;
    }

    // @dev Checks if the bond's tranches can be accepted into the tranche queue.
    //      * Expects the bond's maturity to be within expected bounds.
    // @return True if the bond is "acceptable".
    function _isAcceptable(IBondController bond) private view returns (bool) {
        // NOTE: `timeToMaturity` will be 0 if the bond is past maturity.
        uint256 timeToMaturity = bond.timeToMaturity();
        return (timeToMaturity >= minTrancheMaturiySec && timeToMaturity < maxTrancheMaturiySec);
    }

    // @dev Calculates the tranche token amount for requested perp amount.
    //      If the tranche balance doesn't cover the exchange, it returns the remainder.
    function _perpsToCoveredTranches(
        ITranche t,
        uint256 perpAmountRequested,
        uint256 yield,
        uint256 price
    ) private view returns (uint256 trancheAmtUsed, uint256 remainder) {
        uint256 trancheBalance = t.balanceOf(_self());
        uint256 trancheAmtForRequested = _perpsToTranches(perpAmountRequested, yield, price);
        trancheAmtUsed = Math.min(trancheAmtForRequested, trancheBalance);
        remainder = trancheAmtUsed > 0
            ? (perpAmountRequested * (trancheAmtForRequested - trancheAmtUsed)).ceilDiv(trancheAmtForRequested)
            : perpAmountRequested;
        return (trancheAmtUsed, remainder);
    }

    // @dev Alias to self.
    function _self() private view returns (address) {
        return address(this);
    }

    // @dev Calculates perp token amount from tranche amount.
    //      perp = (tranche * yield) * price
    function _tranchesToPerps(
        uint256 trancheAmt,
        uint256 yield,
        uint256 price
    ) private pure returns (uint256) {
        return (((trancheAmt * yield) / (10**YIELD_DECIMALS)) * price) / (10**PRICE_DECIMALS);
    }

    // @dev Calculates tranche token amount from perp amount.
    //      tranche = perp / (price * yield)
    function _perpsToTranches(
        uint256 amount,
        uint256 yield,
        uint256 price
    ) private pure returns (uint256) {
        return yield > 0 && price > 0 ? (((amount * (10**PRICE_DECIMALS)) / price) * (10**YIELD_DECIMALS)) / yield : 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
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
library SafeCast {
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
library SignedMath {
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

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
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[owner][spender];
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
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
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
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

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
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
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

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

struct AddressQueue {
    // @notice Mapping between queue index and address.
    mapping(uint256 => address) queue;
    // @notice Mapping to check address existence.
    mapping(address => bool) items;
    // @notice Index of the first address.
    uint256 first;
    // @notice Index of the last address.
    uint256 last;
}

/*
 *  @title AddressQueueHelpers
 *
 *  @notice Library to handle a queue of addresses and basic operations like enqueue and dequeue.
 *          It also supports O(1) existence check, and head, tail retrieval.
 *
 *  @dev Original implementation: https://github.com/chriseth/solidity-examples/blob/master/queue.sol
 */
library AddressQueueHelpers {
    // @notice Initialize the queue storage.
    // @param q Queue storage.
    function init(AddressQueue storage q) internal {
        q.first = 1;
        q.last = 0;
    }

    // @notice Add address to the queue.
    // @param q Queue storage.
    // @param a Address to be added to the queue.
    function enqueue(AddressQueue storage q, address a) internal {
        require(a != address(0), "AddressQueueHelpers: Expected valid item");
        q.last += 1;
        q.queue[q.last] = a;
        q.items[a] = true;
    }

    // @notice Removes the address at the tail of the queue.
    // @param q Queue storage.
    function dequeue(AddressQueue storage q) internal returns (address) {
        require(q.last >= q.first, "AddressQueueHelpers: Expected non-empty queue");
        address a = q.queue[q.first];
        delete q.queue[q.first];
        delete q.items[a];
        q.first += 1;
        return a;
    }

    // @notice Fetches the address at the head of the queue.
    // @param q Queue storage.
    // @return The address at the head of the queue.
    function head(AddressQueue storage q) internal view returns (address) {
        return q.queue[q.first]; // at(0)
    }

    // @notice Fetches the address at the tail of the queue.
    // @param q Queue storage.
    // @return The address at the tail of the queue.
    function tail(AddressQueue storage q) internal view returns (address) {
        return q.queue[q.last]; // at(length-1)
    }

    // @notice Checks if the given address is in the queue.
    // @param q Queue storage.
    // @param a The address to check.
    // @return True if address is present and False if not.
    function contains(AddressQueue storage q, address a) internal view returns (bool) {
        return q.items[a];
    }

    // @notice Calculates the number of items in the queue.
    // @param q Queue storage.
    // @return The queue size.
    function length(AddressQueue storage q) internal view returns (uint256) {
        return q.last >= q.first ? q.last - q.first + 1 : 0;
    }

    // @notice Fetches the item at a given index (indexed from 0 to length-1).
    // @param q Queue storage.
    // @param i Index to look up.
    // @return The item at given index.
    function at(AddressQueue storage q, uint256 index) internal view returns (address) {
        require(index < length(q), "AddressQueueHelpers: Expected index to be in bounds");
        return q.queue[q.first + index];
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IBondController } from "../_interfaces/buttonwood/IBondController.sol";
import { ITranche } from "../_interfaces/buttonwood/ITranche.sol";

struct TrancheData {
    ITranche[] tranches;
    uint256[] trancheRatios;
    uint8 trancheCount;
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
    // @return The duration in seconds .
    function duration(IBondController b) internal view returns (uint256) {
        return b.maturityDate() - b.creationDate();
    }

    // @notice Given a bond, retrieves all of the bond's tranche related data.
    // @param b The address of the bond contract.
    // @return The tranche data.
    function getTrancheData(IBondController b) internal view returns (TrancheData memory td) {
        // Max tranches per bond < 2**8 - 1
        td.trancheCount = uint8(b.trancheCount());
        td.tranches = new ITranche[](td.trancheCount);
        td.trancheRatios = new uint256[](td.trancheCount);
        for (uint8 i = 0; i < td.trancheCount; i++) {
            (ITranche t, uint256 ratio) = b.tranches(i);
            td.tranches[i] = t;
            td.trancheRatios[i] = ratio;
        }
        return td;
    }

    // TODO: move off-chain helpers to a different file?
    // @notice Helper function to estimate the amount of tranches minted when a given amount of collateral
    //         is deposited into the bond.
    // @dev This function is used off-chain services (using callStatic) to preview tranches minted after
    // @param b The address of the bond contract.
    // @return The tranche data, an array of tranche amounts and fees.
    function previewDeposit(IBondController b, uint256 collateralAmount)
        internal
        view
        returns (
            TrancheData memory td,
            uint256[] memory trancheAmts,
            uint256[] memory fees
        )
    {
        td = getTrancheData(b);

        uint256 totalDebt = b.totalDebt();
        uint256 collateralBalance = IERC20(b.collateralToken()).balanceOf(address(b));
        uint256 feeBps = b.feeBps();

        trancheAmts = new uint256[](td.trancheCount);
        fees = new uint256[](td.trancheCount);
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

    // @notice Given a bond, retrieves the collateral currently redeemable for
    //         each tranche held by the given address.
    // @param b The address of the bond contract.
    // @param u The address to check balance for.
    // @return The tranche data and an array of collateral amounts.
    function getTrancheCollateralBalances(IBondController b, address u)
        internal
        view
        returns (TrancheData memory td, uint256[] memory balances)
    {
        td = getTrancheData(b);

        balances = new uint256[](td.trancheCount);

        if (b.isMature()) {
            for (uint8 i = 0; i < td.trancheCount; i++) {
                uint256 trancheCollaterBalance = IERC20(b.collateralToken()).balanceOf(address(td.tranches[i]));
                balances[i] = (td.tranches[i].balanceOf(u) * trancheCollaterBalance) / td.tranches[i].totalSupply();
            }
            return (td, balances);
        }

        uint256 bondCollateralBalance = IERC20(b.collateralToken()).balanceOf(address(b));
        for (uint8 i = 0; i < td.trancheCount - 1; i++) {
            uint256 trancheSupply = td.tranches[i].totalSupply();
            uint256 trancheCollaterBalance = trancheSupply <= bondCollateralBalance
                ? trancheSupply
                : bondCollateralBalance;
            balances[i] = (td.tranches[i].balanceOf(u) * trancheCollaterBalance) / trancheSupply;
            bondCollateralBalance -= trancheCollaterBalance;
        }
        balances[td.trancheCount - 1] = (bondCollateralBalance > 0) ? bondCollateralBalance : 0;
        return (td, balances);
    }
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
        require(false, "TrancheDataHelpers: Expected tranche to be part of bond");
        return type(uint256).max;
    }
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

// SPDX-License-Identifier: GPL-3.0-or-later

// solhint-disable-next-line compiler-version
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITranche is IERC20 {
    function bond() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later

// solhint-disable-next-line compiler-version
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

// solhint-disable-next-line compiler-version
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IBondIssuer } from "./IBondIssuer.sol";
import { IFeeStrategy } from "./IFeeStrategy.sol";
import { IPricingStrategy } from "./IPricingStrategy.sol";
import { IBondController } from "./buttonwood/IBondController.sol";
import { ITranche } from "./buttonwood/ITranche.sol";

interface IPerpetualTranche is IERC20 {
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

    // @notice Event emitted when maturity tolerance parameters are updated.
    // @param min The minimum maturity time.
    // @param max The maximum maturity time.
    event UpdatedTolerableTrancheMaturiy(uint256 min, uint256 max);

    // @notice Event emitted when the defined tranche yields are updated.
    // @param hash The tranche class hash.
    // @param yield The yield factor for any tranche belonging to that class.
    event UpdatedDefinedTrancheYields(bytes32 hash, uint256 yield);

    // @notice Event emitted when the applied yield for a given tranche is set.
    // @param tranche The address of the tranche token.
    // @param yield The yield factor applied.
    event TrancheYieldApplied(ITranche tranche, uint256 yield);

    // @notice Event emitted when a new tranche is added to the queue head.
    // @param strategy Address of the tranche added to the queue.
    event TrancheEnqueued(ITranche tranche);

    // @notice Event emitted when a tranche is removed from the queue tail.
    // @param strategy Address of the tranche removed from the queue.
    event TrancheDequeued(ITranche tranche);

    // @notice Event emitted the reserve's current token balance is recorded after change.
    // @param token Address of token.
    // @param balance The recorded ERC-20 balance of the token held by the reserve.
    event ReserveSynced(IERC20 token, uint256 balance);

    //--------------------------------------------------------------------------
    // Methods

    // @notice Deposits tranche tokens into the system and mint perp tokens.
    // @param trancheIn The address of the tranche token to be deposited.
    // @param trancheInAmt The amount of tranche tokens deposited.
    // @return mintAmt The amount of perp tokens minted to the caller.
    // @return fee The fee paid by the caller.
    function deposit(ITranche trancheIn, uint256 trancheInAmt) external returns (uint256 mintAmt, int256 mintFee);

    // @notice Redeem tranche tokens by burning perp tokens.
    // @param trancheOut The tranche token to be redeemed.
    // @param amountRequested The amount of perp tokens requested to be burnt.
    // @return burnAmt The amount of perp tokens burnt from the caller.
    // @return fee The fee paid by the caller.
    function redeem(ITranche trancheOut, uint256 amountRequested) external returns (uint256 burnAmt, int256 burnFee);

    // @notice Rotates newer tranches in for older tranches.
    // @param trancheIn The tranche token deposited.
    // @param trancheOut The tranche token to be redeemed.
    // @param trancheInAmt The amount of trancheIn tokens deposited.
    // @return trancheOutAmt The amount of trancheOut tokens redeemed.
    // @return rolloverFee The fee paid by the caller.
    function rollover(
        ITranche trancheIn,
        ITranche trancheOut,
        uint256 trancheInAmt
    ) external returns (uint256 trancheOutAmt, int256 rolloverFee);

    // @notice Burn perp tokens without redemption.
    // @param amount Amount of perp tokens to be burnt.
    // @return True if burn is successful.
    function burn(uint256 amount) external returns (bool);

    // @notice The parent bond whose tranches are currently accepted to mint perp tokens.
    // @return Address of the deposit bond.
    function getDepositBond() external returns (IBondController);

    // @notice Tranche up for redemption next.
    // @return Address of the tranche token.
    function getRedemptionTranche() external returns (ITranche);

    // @notice Total count of tokens in the redemption queue.
    function getRedemptionQueueCount() external returns (uint256);

    // @notice The token address from the redemption queue by index.
    // @param index The index of a token.
    function getRedemptionQueueAt(uint256 index) external returns (address);

    // @notice Checks if the given `trancheIn` can be rolled out for `trancheOut`.
    // @param trancheIn The tranche token deposited.
    // @param trancheOut The tranche token to be redeemed.
    function isAcceptableRollover(ITranche trancheIn, ITranche trancheOut) external returns (bool);

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
    function feeToken() external view returns (IERC20);

    // @notice The yield to be applied given the tranche.
    // @param tranche The address of the tranche token.
    // @return The yield applied.
    function trancheYield(ITranche tranche) external view returns (uint256);

    // @notice The computes the class hash of a given tranche.
    // @dev This is used to identify different tranche tokens instances of the same class.
    // @param tranche The address of the tranche token.
    // @return The class hash.
    function trancheClass(ITranche t) external view returns (bytes32);

    // @notice The price of the given tranche.
    // @param tranche The address of the tranche token.
    // @return The computed price.
    function tranchePrice(ITranche tranche) external view returns (uint256);

    // @notice Computes the amount of perp token amount that can be exchanged for given tranche and amount.
    // @param tranche The address of the tranche token.
    // @param trancheAmt The amount of tranche tokens.
    // @return The perp token amount.
    function tranchesToPerps(ITranche tranche, uint256 trancheAmt) external view returns (uint256);

    // @notice Computes the amount of tranche tokens amount that can be exchanged for given perp token amount.
    // @param tranche The address of the tranche token.
    // @param trancheAmt The amount of perp tokens.
    // @return The tranche token amount.
    function perpsToTranches(ITranche tranche, uint256 amount) external view returns (uint256);

    // @notice Computes the maximum amount of tranche tokens amount that
    //         can be exchanged for the requested perp token amount covered by the systems tranche balance.
    //         If the system doesn't have enough tranche tokens to cover the exchange,
    //         it computes the remainder perp tokens which cannot be exchanged.
    // @param tranche The address of the tranche token.
    // @param amountRequested The amount of perp tokens to exchange.
    // @return trancheAmtUsed The tranche tokens used for the exchange.
    // @return remainder The number of perp tokens which cannot be exchanged.
    function perpsToCoveredTranches(ITranche tranche, uint256 amountRequested)
        external
        view
        returns (uint256 trancheAmtUsed, uint256 remainder);

    // @notice Total count of tokens held in the reserve.
    function reserveCount() external view returns (uint256);

    // @notice The token address from the reserve list by index.
    // @param index The index of a token.
    function reserveAt(uint256 index) external view returns (address);

    // @notice Checks if the given token is part of the reserve list.
    // @param token The address of a token to check.
    function inReserve(IERC20 token) external view returns (bool);

    // @notice Updates time dependent queue state.
    function updateQueue() external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

// solhint-disable-next-line compiler-version
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
    function totalIssued() external view returns (uint256);

    // @notice The bond address from the issued list by index.
    // @return Address of the bond.
    function issuedBondAt(uint256 index) external view returns (IBondController);
}

// SPDX-License-Identifier: GPL-3.0-or-later

// solhint-disable-next-line compiler-version
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IFeeStrategy {
    // @notice Address of the fee token.
    function feeToken() external view returns (IERC20);

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

// solhint-disable-next-line compiler-version
import { ITranche } from "./buttonwood/ITranche.sol";

interface IPricingStrategy {
    // @notice Computes the price of a given tranche.
    // @param tranche The tranche to compute price of.
    // @return The price as a fixed point number with `decimals()`.
    function computeTranchePrice(ITranche tranche) external view returns (uint256);

    // @notice Number of price decimals.
    function decimals() external view returns (uint8);
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