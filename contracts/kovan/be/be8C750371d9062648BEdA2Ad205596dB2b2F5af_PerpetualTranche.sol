// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { SignedMath } from "@openzeppelin/contracts/utils/math/SignedMath.sol";

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { AddressQueue, AddressQueueHelpers } from "./_utils/AddressQueueHelpers.sol";
import { TrancheData, TrancheDataHelpers, BondHelpers } from "./_utils/BondHelpers.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ITranche } from "./_interfaces/buttonwood/ITranche.sol";
import { IBondController } from "./_interfaces/buttonwood/IBondController.sol";

import { MintData, BurnData, RolloverData, IPerpetualTranche } from "./_interfaces/IPerpetualTranche.sol";
import { IBondIssuer } from "./_interfaces/IBondIssuer.sol";
import { IFeeStrategy } from "./_interfaces/IFeeStrategy.sol";
import { IPricingStrategy } from "./_interfaces/IPricingStrategy.sol";

/*
 *  @title PerpetualTranche
 *
 *  @notice An opinionated implementation of a perpetual tranche ERC-20 token contract.
 *          Perp tokens are backed by tranche tokens. Users can mint perp tokens by depositing tranches.
 *          They can redeem tranches by burning their perp tokens.
 *
 *          The PerpetualTranche contract enforces tranche deposits/redemption through a FIFO bond queue.
 *          The queue is ordered by the bond's maturity date, the tail of the queue has the newest bond
 *          i.e) the one that matures furthest out into the future.
 *          Incentivized parties can "rollover" tranches which are approaching maturity for
 *          tranches at tail of the bond queue.
 *
 */
contract PerpetualTranche is ERC20, Initializable, Ownable, IPerpetualTranche {
    using SignedMath for int256;
    using SafeERC20 for IERC20;
    using SafeERC20 for ITranche;
    using EnumerableSet for EnumerableSet.AddressSet;
    using AddressQueueHelpers for AddressQueue;
    using BondHelpers for IBondController;
    using TrancheDataHelpers for TrancheData;

    //-------------------------------------------------------------------------
    // Constants & Immutables
    uint8 public constant YIELD_DECIMALS = 6;
    uint8 public constant PRICE_DECIMALS = 18;

    // @dev Number of ERC-20 decimal places to get the perp token amount user representation.
    uint8 private immutable _decimals;

    //-------------------------------------------------------------------------
    // Data

    // @notice Issuer stores a predefined bond config and frequency and issues new bonds when poked
    // @dev Only tranches of bonds issued by the whitelisted issuer are accepted by the system.
    IBondIssuer public bondIssuer;

    // @notice External contract points to the fee token and computes mint, burn fees and rollover rewards.
    IFeeStrategy public feeStrategy;

    // @notice External contract that computes a given tranche's price.
    // @dev The computed price is expected to be a fixed point unsigned integer with {PRICE_DECIMALS} decimals.
    IPricingStrategy public pricingStrategy;

    // @notice Yield factor applied on tranches transferred into or out of the system.
    // @dev A given tranche's yield is specific to it's parent bond's class
    //      i.e) the unique combination of the bond's {collateralToken, trancheRatios}.
    //      The yield is specified as a fixed point unsigned integer with {YIELD_DECIMALS} decimals.
    mapping(bytes32 => uint256[]) private _trancheYields;

    // @notice A FIFO queue of bonds, each of which have an associated number of seniority-based tranches.
    // @dev The system only accepts tranches from bond at the tail of the queue to mint perpetual tokens.
    //      The system burns perpetual tokens for tranches from bonds at the head of the queue.
    AddressQueue public bondQueue;

    // @notice A record of all tranches with a balance held in the reserve which backs spot supply.
    EnumerableSet.AddressSet private _reserveTranches;

    // @notice The minimum maturity time in seconds for a bond below which can get removed from the bond queue.
    uint256 public minMaturiySec;

    // @notice The maximum maturity time in seconds for a bond above which it can't get added into the bond queue.
    uint256 public maxMaturiySec;

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
        IPricingStrategy pricingStrategy_,
        IFeeStrategy feeStrategy_
    ) public initializer {
        require(address(bondIssuer_) != address(0), "Expected new bond minter to be set");
        require(address(feeStrategy_) != address(0), "Expected new fee strategy to be set");
        require(address(pricingStrategy_) != address(0), "Expected new pricing strategy to be set");

        bondIssuer = bondIssuer_;
        feeStrategy = feeStrategy_;
        pricingStrategy = pricingStrategy_;

        bondQueue.init();
    }

    //--------------------------------------------------------------------------
    // ADMIN only methods

    // @notice Update the reference to the bond issuer contract.
    // @param bondIssuer_ New bond issuer address.
    function updateBondIssuer(IBondIssuer bondIssuer_) external onlyOwner {
        require(address(bondIssuer_) != address(0), "Expected new bond minter to be set");
        bondIssuer = bondIssuer_;
        emit BondIssuerUpdated(bondIssuer_);
    }

    // @notice Update the reference to the fee strategy contract.
    // @param feeStrategy_ New strategy address.
    function updateFeeStrategy(IFeeStrategy feeStrategy_) external onlyOwner {
        require(address(feeStrategy_) != address(0), "Expected new fee strategy to be set");
        feeStrategy = feeStrategy_;
        emit FeeStrategyUpdated(feeStrategy_);
    }

    // @notice Update the reference to the pricing strategy contract.
    // @param pricingStrategy_ New strategy address.
    function updatePricingStrategy(IPricingStrategy pricingStrategy_) external onlyOwner {
        require(address(pricingStrategy_) != address(0), "Expected new pricing strategy to be set");
        require(pricingStrategy_.decimals() == PRICE_DECIMALS, "Expected new pricing stragey to use same decimals");
        pricingStrategy = pricingStrategy_;
        emit PricingStrategyUpdated(pricingStrategy_);
    }

    // @notice Update the maturity tolerance parameters.
    // @param minMaturiySec_ New minimum maturity time.
    // @param maxMaturiySec_ New maximum maturity time.
    function updateTolerableBondMaturiy(uint256 minMaturiySec_, uint256 maxMaturiySec_) external onlyOwner {
        minMaturiySec = minMaturiySec_;
        maxMaturiySec = maxMaturiySec_;
        emit TolerableBondMaturiyUpdated(minMaturiySec_, maxMaturiySec_);
    }

    // @notice Updates the the bond yields referenced by the class hash.
    // @param hash The bond class.
    // @param yields The list of yields for each tranche.
    function updateBondYields(bytes32 hash, uint256[] memory yields) external onlyOwner {
        _trancheYields[hash] = yields;
        emit TrancheYieldsUpdated(hash, yields);
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
        require(!_reserveTranches.contains(address(token)), "Expected token to not be reserve asset");
        token.safeTransfer(to, amount);
    }

    //--------------------------------------------------------------------------
    // External methods

    /// @inheritdoc IPerpetualTranche
    function deposit(ITranche trancheIn, uint256 trancheInAmt) external override returns (MintData memory m) {
        // assert(bondIssuer != address(0)); // bond minter not set

        m = previewDeposit(trancheIn, trancheInAmt);
        if (m.amount == 0) {
            return m;
        }

        trancheIn.safeTransferFrom(_msgSender(), address(this), trancheInAmt);
        _syncReserve(trancheIn);

        // NOTE: user approves fee in advance, in case the fee is paid in the native token
        _mint(_msgSender(), m.amount);
        _settleFee(_msgSender(), m.fee);

        return m;
    }

    /// @inheritdoc IPerpetualTranche
    function previewDeposit(ITranche trancheIn, uint256 trancheInAmt) public override returns (MintData memory m) {
        IBondController bond = getMintingBond();
        require(address(bond) != address(0), "Expected minting bond to be set");

        m.amount = _tranchesToPerps(
            trancheInAmt,
            _trancheYield(bond, bond.getTrancheData(), trancheIn),
            _tranchePrice(trancheIn)
        );
        m.fee = feeStrategy.computeMintFee(m.amount);

        return m;
    }

    /// @inheritdoc IPerpetualTranche
    function redeem(uint256 requestedAmount) external override returns (BurnData memory b) {
        b = previewRedeem(requestedAmount);
        if (b.amount == 0) {
            return b;
        }

        for (uint8 i = 0; i < b.trancheCount; i++) {
            b.tranches[i].safeTransfer(_msgSender(), b.trancheAmts[i]);
            _syncReserve(b.tranches[i]);
        }

        // NOTE: user approves burn amount + fee in case the fee is paid in the native token
        _burn(_msgSender(), b.amount);
        _settleFee(_msgSender(), b.fee);

        return b;
    }

    /// @inheritdoc IPerpetualTranche
    function previewRedeem(uint256 requestedAmount) public override returns (BurnData memory b) {
        IBondController bond = getBurningBond();
        TrancheData memory td = bond.getTrancheData();

        b.remainder = requestedAmount;
        while (address(bond) != address(0) && b.remainder > 0) {
            for (uint8 i = 0; i < td.trancheCount; i++) {
                ITranche t = td.tranches[i];

                uint256 trancheAmt;
                (trancheAmt, b.remainder) = _perpsToTranchesWithRemainder(
                    t,
                    b.remainder,
                    _trancheYield(bond, td, t),
                    _tranchePrice(t)
                );
                if (trancheAmt == 0) {
                    continue;
                }

                b.trancheAmts[i] = trancheAmt;
                b.tranches[b.trancheCount] = t;
                b.trancheCount++;
            }

            if (b.remainder == 0) {
                break;
            }

            // we've burned through all the bond tranches and now can move to the next one
            bondQueue.dequeue();
            bond = getBurningBond();
            td = bond.getTrancheData();
        }

        b.amount = requestedAmount - b.remainder;
        b.fee = feeStrategy.computeBurnFee(b.amount);
        // asset(requestedAmount == (b.amount + b.remainder));

        return b;
    }

    /// @inheritdoc IPerpetualTranche
    function redeemIcebox(ITranche trancheOut, uint256 requestedAmount) external override returns (BurnData memory b) {
        b = previewRedeemIcebox(trancheOut, requestedAmount);
        if (b.amount == 0) {
            return b;
        }

        b.tranches[0].safeTransfer(_msgSender(), b.trancheAmts[0]);
        _syncReserve(b.tranches[0]);

        _burn(_msgSender(), b.amount);
        _settleFee(_msgSender(), b.fee);

        return b;
    }

    /// @inheritdoc IPerpetualTranche
    function previewRedeemIcebox(ITranche trancheOut, uint256 requestedAmount)
        public
        view
        override
        returns (BurnData memory b)
    {
        require(bondQueue.length() == 0, "Expected bond queue to be empty");

        IBondController bond = IBondController(trancheOut.bond());
        TrancheData memory td = bond.getTrancheData();

        uint256 trancheAmt;
        (trancheAmt, b.remainder) = _perpsToTranchesWithRemainder(
            trancheOut,
            requestedAmount,
            _trancheYield(bond, td, trancheOut),
            _tranchePrice(trancheOut)
        );
        if (trancheAmt == 0) {
            return b;
        }

        b.trancheAmts[0] = trancheAmt;
        b.tranches[0] = trancheOut;
        b.trancheCount = 1;

        b.amount = requestedAmount - b.remainder;
        b.fee = feeStrategy.computeBurnFee(b.amount);

        return b;
    }

    /// @inheritdoc IPerpetualTranche
    function rollover(
        ITranche trancheIn,
        ITranche trancheOut,
        uint256 trancheInAmt
    ) external override returns (RolloverData memory r) {
        r = previewRollover(trancheIn, trancheOut, trancheInAmt);
        if (r.amount == 0) {
            return r;
        }

        trancheIn.safeTransferFrom(_msgSender(), reserve(), trancheInAmt);
        _syncReserve(trancheIn);

        trancheOut.safeTransfer(_msgSender(), r.trancheAmt);
        _syncReserve(trancheOut);

        _settleReward(_msgSender(), r.reward);

        return r;
    }

    /// @inheritdoc IPerpetualTranche
    function previewRollover(
        ITranche trancheIn,
        ITranche trancheOut,
        uint256 trancheInAmt
    ) public override returns (RolloverData memory r) {
        IBondController bondIn = IBondController(trancheIn.bond());
        IBondController bondOut = IBondController(trancheOut.bond());

        require(bondIn == getMintingBond(), "Expected trancheIn bond to be minting bond");
        require(!bondQueue.contains(address(bondOut)), "Expected trancheOut bond NOT to be in the queue");

        r.amount = _tranchesToPerps(
            trancheInAmt,
            _trancheYield(bondIn, bondIn.getTrancheData(), trancheIn),
            _tranchePrice(trancheIn)
        );
        r.trancheAmt = _perpsToTranches(
            r.amount,
            _trancheYield(bondOut, bondOut.getTrancheData(), trancheOut),
            _tranchePrice(trancheOut)
        );
        r.reward = feeStrategy.computeRolloverReward(r.amount);
        return r;
    }

    /// @inheritdoc IPerpetualTranche
    // @dev Used incase an altruistic party intends to increase the collaterlization ratio.
    function burn(uint256 amount) external override returns (bool) {
        _burn(_msgSender(), amount);
        return true;
    }

    //--------------------------------------------------------------------------
    // Public methods

    /// @inheritdoc IPerpetualTranche
    // @dev Newest bond in the queue (i.e the one with the furthest out maturity)
    //      will be at the tail of the queue.
    //      Lazily pushes a new acceptable bond into the queue so that the tail is up to date.
    function getMintingBond() public override returns (IBondController mintingBond) {
        mintingBond = IBondController(bondQueue.tail());
        IBondController newBond = bondIssuer.getLastBond();

        if (mintingBond == newBond || !isAcceptable(newBond)) {
            return mintingBond;
        }

        // assert(newBond != address(0));
        // assert(bondIssuer.isInstance(newBond));
        // assert(!bondQueue.contains(address(newBond)));

        mintingBond = newBond;

        // NOTE: The new bond is pushed to the tail of the queue.
        bondQueue.enqueue(address(mintingBond));
        emit BondEnqueued(mintingBond);

        // assert(mintingBond == IBondController(bondQueue.tail()));
        return mintingBond;
    }

    /// @inheritdoc IPerpetualTranche
    // @dev Oldest bond in the queue (i.e the one with the most immediate maturity)
    //      will be at the head of the queue.
    //      Lazily dequeues bonds till the head of the queue has an acceptable bond.
    function getBurningBond() public override returns (IBondController burningBond) {
        burningBond = IBondController(bondQueue.head());

        while (address(burningBond) != address(0) && !isAcceptable(burningBond)) {
            // NOTE: The oldest bond is removed from the head of the queue.
            bondQueue.dequeue();
            emit BondDequeued(burningBond);

            burningBond = IBondController(bondQueue.head());
        }

        // assert(burningBond == IBondController(bondQueue.head()));
        return burningBond;
    }

    //--------------------------------------------------------------------------
    // External view methods

    /// @inheritdoc IPerpetualTranche
    function trancheYield(ITranche t) external view override returns (uint256) {
        IBondController bond = IBondController(t.bond());
        return _trancheYield(bond, bond.getTrancheData(), t);
    }

    /// @inheritdoc IPerpetualTranche
    function tranchePrice(ITranche t) external view override returns (uint256) {
        return _tranchePrice(t);
    }

    /// @inheritdoc IPerpetualTranche
    function tranchesToPerps(ITranche t, uint256 trancheAmt) external view override returns (uint256) {
        IBondController bond = IBondController(t.bond());
        return _tranchesToPerps(trancheAmt, _trancheYield(bond, bond.getTrancheData(), t), _tranchePrice(t));
    }

    /// @inheritdoc IPerpetualTranche
    function perpsToTranches(ITranche t, uint256 amount) external view override returns (uint256) {
        IBondController bond = IBondController(t.bond());
        return _perpsToTranches(amount, _trancheYield(bond, bond.getTrancheData(), t), _tranchePrice(t));
    }

    //--------------------------------------------------------------------------
    // Public view methods

    /// @inheritdoc IPerpetualTranche
    function feeToken() public view override returns (IERC20) {
        return feeStrategy.feeToken();
    }

    /// @inheritdoc IPerpetualTranche
    function rewardToken() public view override returns (IERC20) {
        return feeStrategy.rewardToken();
    }

    /// @inheritdoc IPerpetualTranche
    function trancheCount() external view override returns (uint256) {
        return _reserveTranches.length();
    }

    /// @inheritdoc IPerpetualTranche
    function trancheAt(uint256 i) external view override returns (address) {
        return _reserveTranches.at(i);
    }

    //--------------------------------------------------------------------------
    // Public view methods

    /**
     * @dev Returns the number of decimals used to get its user representation.
     *      For example, if `decimals` equals `2`, a balance of `505` tokens should
     *      be displayed to a user as `5.05` (`505 / 10 ** 2`).
     */
    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    /// @inheritdoc IPerpetualTranche
    function reserve() public view override returns (address) {
        return address(this);
    }

    // @notice Checks if the bond can be accepted into the system based on the following conditions.
    //         * If maturity is within defined bounds
    // @dev Only "acceptable" bonds can be added to the queue.
    //      If a bond becomes "unacceptable" it can get removed from the queue.
    // @param The address of the bond to check.
    // @return True if the bond is "acceptable".
    function isAcceptable(IBondController bond) public view returns (bool) {
        uint256 timeToMaturity = bond.timeToMaturity();
        return ((timeToMaturity >= minMaturiySec) && (timeToMaturity < maxMaturiySec));
    }

    function queueLen() public view returns (uint256) {
        return bondQueue.length();
    }

    function queueAt(uint256 index) public view returns (address) {
        return bondQueue.queue[index];
    }

    function queue() public view returns (uint256,uint256) {
        return (bondQueue.first, bondQueue.last);
    }

    //--------------------------------------------------------------------------
    // Private/Internal helper methods

    // @dev Keeps the list of tranches held in the reserve up to date.
    //      Spot is backed by tranches in this list.
    function _syncReserve(ITranche t) internal {
        uint256 balance = t.balanceOf(reserve());
        bool inReserve = _reserveTranches.contains(address(t));
        if (balance > 0 && !inReserve) {
            _reserveTranches.add(address(t));
        } else if (balance == 0 && inReserve) {
            _reserveTranches.remove(address(t));
        }
        emit ReserveSynced(t, balance);
    }

    // @dev If the fee is positive, fee is transferred to the reserve from payer
    //      else it's transferred to the payer from the reserve.
    function _settleFee(address payer, int256 fee) internal {
        IERC20 feeToken_ = feeStrategy.feeToken();
        uint256 fee_ = fee.abs();

        if (fee >= 0) {
            feeToken_.safeTransferFrom(payer, reserve(), fee_);
        } else {
            feeToken_.safeTransfer(payer, fee_);
        }
    }

    // @dev If the reward is positive, reward is transferred from the reserve to the payer
    //      else it's transferred from the payer to the reserve.
    function _settleReward(address payer, int256 reward) internal {
        IERC20 rewardToken_ = feeStrategy.rewardToken();
        uint256 reward_ = reward.abs();

        if (reward >= 0) {
            rewardToken_.safeTransfer(payer, reward_);
        } else {
            rewardToken_.safeTransferFrom(payer, reserve(), reward_);
        }
    }

    // @dev Fetches the tranche yield from storage.
    function _trancheYield(
        IBondController bond,
        TrancheData memory td,
        ITranche t
    ) internal view returns (uint256) {
        // NOTE: `getTrancheIndex` reverts if trancheIn is NOT part of the minting bond
        return _trancheYields[_bondClass(bond.collateralToken(), td.trancheRatios)][td.getTrancheIndex(t)];
    }

    // @notice Queries the pricing strategy for the given tranche's price.
    function _tranchePrice(ITranche t) internal view returns (uint256) {
        return pricingStrategy.computeTranchePrice(t);
    }

    // @dev Calculates the tranche token amount for requested perp amount.
    //      If the reserve's tranche balance doesn't cover the exchange, it returns the remainder.
    function _perpsToTranchesWithRemainder(
        ITranche t,
        uint256 requestedAmount,
        uint256 yield,
        uint256 price
    ) private view returns (uint256 trancheAmtUsed, uint256 remainder) {
        uint256 trancheBalance = t.balanceOf(reserve());
        uint256 trancheAmtForRequested = _perpsToTranches(requestedAmount, yield, price);
        trancheAmtUsed = (trancheAmtForRequested < trancheBalance) ? trancheAmtForRequested : trancheBalance;
        remainder = requestedAmount;
        if (trancheAmtUsed > 0) {
            // NOTE: we assume that tranche to burnAmt back to tranche will be lossless
            remainder = (requestedAmount * (trancheAmtForRequested - trancheAmtUsed)) / trancheAmtForRequested;
        }
        return (trancheAmtUsed, remainder);
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
        return (((amount * (10**PRICE_DECIMALS)) / price) * (10**YIELD_DECIMALS)) / yield;
    }

    // @notice Computes the bond's class hash.
    function _bondClass(address collateralToken, uint256[] memory trancheRatios) private pure returns (bytes32) {
        return keccak256(abi.encode(collateralToken, trancheRatios));
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

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

struct AddressQueue {
    // @notice Mapping between queue index and address.
    mapping(uint256 => address) queue;
    // @notice Mapping to check address existance.
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
        return q.queue[q.first];
    }

    // @notice Fetches the address at the tail of the queue.
    // @param q Queue storage.
    // @return The address at the tail of the queue.
    function tail(AddressQueue storage q) internal view returns (address) {
        return q.queue[q.last];
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
        return q.last - q.first + 1;
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
    uint256 trancheCount;
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

    // @notice Given a bond, calculates the bond duration ie
    //         difference between creation time and matuirty time.
    // @param b The address of the bond contract.
    // @return The duration in seconds .
    function duration(IBondController b) internal view returns (uint256) {
        return b.maturityDate() - b.creationDate();
    }

    // @notice Given a bond, retrieves all of the bond's tranche related data.
    // @param b The address of the bond contract.
    // @return The tranche data.
    function getTrancheData(IBondController b) internal view returns (TrancheData memory td) {
        td.trancheCount = b.trancheCount();
        // Max tranches per bond < 2**8 - 1
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
    // @return The tranche data and an array of tranche amounts.
    function previewDeposit(IBondController b, uint256 collateralAmount)
        internal
        view
        returns (
            TrancheData memory td,
            uint256[] memory trancheAmts,
            uint256 fee
        )
    {
        td = getTrancheData(b);

        uint256 totalDebt = b.totalDebt();
        uint256 collateralBalance = IERC20(b.collateralToken()).balanceOf(address(b));
        uint256 feeBps = b.feeBps();

        for (uint256 i = 0; i < td.trancheCount; i++) {
            uint256 trancheValue = (collateralAmount * td.trancheRatios[i]) / TRANCHE_RATIO_GRANULARITY;
            if (collateralBalance > 0) {
                trancheValue = (trancheValue * totalDebt) / collateralBalance;
            }
            fee = (trancheValue * feeBps) / BPS;
            if (fee > 0) {
                trancheValue -= fee;
            }
            trancheAmts[i] = trancheValue;
        }

        return (td, trancheAmts, fee);
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

struct MintData {
    uint256 amount;
    int256 fee;
}

struct BurnData {
    uint256 amount;
    int256 fee;
    uint256 remainder;
    ITranche[] tranches;
    uint256[] trancheAmts;
    uint8 trancheCount;
}

struct RolloverData {
    uint256 amount;
    int256 reward;
    uint256 trancheAmt;
}

interface IPerpetualTranche is IERC20 {
    //--------------------------------------------------------------------------
    // Events

    // @notice Event emitted when the bond issuer is updated.
    // @param issuer Address of the issuer contract.
    event BondIssuerUpdated(IBondIssuer issuer);

    // @notice Event emitted when the fee strategy is updated.
    // @param strategy Address of the strategy contract.
    event FeeStrategyUpdated(IFeeStrategy strategy);

    // @notice Event emitted when the pricing strategy is updated.
    // @param strategy Address of the strategy contract.
    event PricingStrategyUpdated(IPricingStrategy strategy);

    // @notice Event emitted when maturity tolerance parameters are updated.
    // @param min The minimum maturity time.
    // @param max The maximum maturity time.
    event TolerableBondMaturiyUpdated(uint256 min, uint256 max);

    // @notice Event emitted when the tranche yields are updated.
    // @param hash The bond class hash.
    // @param yields The yeild for each tranche.
    event TrancheYieldsUpdated(bytes32 hash, uint256[] yields);

    // @notice Event emitted when a new bond is added to the queue head.
    // @param strategy Address of the bond added to the queue.
    event BondEnqueued(IBondController bond);

    // @notice Event emitted when a bond is removed from the queue tail.
    // @param strategy Address of the bond removed from the queue.
    event BondDequeued(IBondController bond);

    // @notice Event emitted the reserve's current token balance is recorded after change.
    // @param t Address of token.
    // @param balance The recorded ERC-20 balance of the token held by the reserve.
    event ReserveSynced(IERC20 t, uint256 balance);

    //--------------------------------------------------------------------------
    // Methods

    // @notice Deposit tranche tokens to mint perp tokens.
    // @param trancheIn The address of the tranche token to be deposited.
    // @param trancheInAmt The amount of tranche tokens deposited.
    // @return The amount of perp tokens minted and the fee charged.
    function deposit(ITranche trancheIn, uint256 trancheInAmt) external returns (MintData memory);

    // @notice Dry-run a deposit operation (without any token transfers).
    // @dev To be used by off-chain services through static invocation.
    // @param trancheIn The address of the tranche token to be deposited.
    // @param trancheInAmt The amount of tranche tokens deposited.
    // @return The amount of perp tokens minted and the fee charged.
    function previewDeposit(ITranche trancheIn, uint256 trancheInAmt) external returns (MintData memory);

    // @notice Redeem perp tokens for tranche tokens.
    // @param requestedAmount The amount of perp tokens requested to be burnt.
    // @return The actual amount of perp tokens burnt, fees and the list of tranches and amounts redeemed.
    function redeem(uint256 requestedAmount) external returns (BurnData memory);

    // @notice Dry-run a redemption operation (without any transfers).
    // @param requestedAmount The amount of perp tokens requested to be burnt.
    // @return The actual amount of perp tokens burnt, fees and the list of tranches and amounts redeemed.
    function previewRedeem(uint256 requestedAmount) external returns (BurnData memory);

    // @notice Redeem perp tokens for tranche tokens from icebox when the bond queue is empty.
    // @param trancheOut The tranche token to be redeemed.
    // @param requestedAmount The amount of perp tokens requested to be burnt.
    // @return The amount of perp tokens burnt, fees.
    function redeemIcebox(ITranche trancheOut, uint256 requestedAmount) external returns (BurnData memory);

    // @notice Dry-run a redemption from icebox operation (without any transfers).
    // @param trancheOut The tranche token to be redeemed.
    // @param requestedAmount The amount of perp tokens requested to be burnt.
    // @return The amount of perp tokens burnt, fees.
    function previewRedeemIcebox(ITranche trancheOut, uint256 requestedAmount) external returns (BurnData memory);

    // @notice Rotates newer tranches in for older tranches.
    // @param trancheIn The tranche token deposited.
    // @param trancheOut The tranche token to be redeemed.
    // @param trancheInAmt The amount of trancheIn tokens deposited.
    // @return The amount of perp tokens rolled over, trancheOut tokens redeemed and reward awarded for rolling over.
    function rollover(
        ITranche trancheIn,
        ITranche trancheOut,
        uint256 trancheInAmt
    ) external returns (RolloverData memory);

    // @notice Dry-run a rollover operation (without any transfers).
    // @param trancheIn The tranche token deposited.
    // @param trancheOut The tranche token to be redeemed.
    // @param trancheInAmt The amount of trancheIn tokens deposited.
    // @return The amount of perp tokens rolled over, trancheOut tokens redeemed and reward awarded for rolling over.
    function previewRollover(
        ITranche trancheIn,
        ITranche trancheOut,
        uint256 trancheInAmt
    ) external returns (RolloverData memory);

    // @notice Burn perp tokens without redemption.
    // @param amount Amount of perp tokens to be burnt.
    // @return True if burn is successful.
    function burn(uint256 amount) external returns (bool);

    // @notice Address of the parent bond whose tranches are currently accepted to mint perp tokens.
    // @return Address of the minting bond.
    function getMintingBond() external returns (IBondController);

    // @notice Address of the parent bond whose tranches are currently redeemed for burning perp tokens.
    // @return Address of the burning bond.
    function getBurningBond() external returns (IBondController);

    // @notice The address of the reserve where the protocol holds funds.
    // @return Address of the reserve.
    function reserve() external view returns (address);

    // @notice The fee token currently used to receive fees in.
    // @return Address of the fee token.
    function feeToken() external view returns (IERC20);

    // @notice The fee token currently used to pay rewards in.
    // @return Address of the reward token.
    function rewardToken() external view returns (IERC20);

    // @notice The yield to be applied given the tranche based on its bond's class and it's seniority.
    // @param t The address of the tranche token.
    // @return The yield applied.
    function trancheYield(ITranche t) external view returns (uint256);

    // @notice The price of the given tranche.
    // @param t The address of the tranche token.
    // @return The computed price.
    function tranchePrice(ITranche t) external view returns (uint256);

    // @notice Computes the amount of perp token amount that can be exchanged for given tranche and amount.
    // @param t The address of the tranche token.
    // @param trancheAmt The amount of tranche tokens.
    // @return The perp token amount.
    function tranchesToPerps(ITranche t, uint256 trancheAmt) external view returns (uint256);

    // @notice Computes the amount of tranche tokens amount that can be exchanged for given perp token amount.
    // @param t The address of the tranche token.
    // @param trancheAmt The amount of perp tokens.
    // @return The tranche token amount.
    function perpsToTranches(ITranche t, uint256 amount) external view returns (uint256);

    // @notice Number of tranche tokens held in the reserve.
    function trancheCount() external view returns (uint256);

    // @notice The tranche address from the tranche list at a given index.
    // @param i The index of the tranche list.
    function trancheAt(uint256 i) external view returns (address);
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
    function getLastBond() external returns (IBondController);
}

// SPDX-License-Identifier: GPL-3.0-or-later

// solhint-disable-next-line compiler-version
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IFeeStrategy {
    // @notice Address of the fee token.
    function feeToken() external view returns (IERC20);

    // @notice Address of the reward token.
    function rewardToken() external view returns (IERC20);

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

    // @notice Computes the reward to rollover given amount of perp tokens.
    // @dev Reward can be either positive or negative. When positive it's paid to the rollover users by the system.
    //      When negative its paid by the rollover users to the system.
    // @param amount The perp-denominated value of the tranches being rotated in.
    // @return The rollover reward in fee tokens.
    function computeRolloverReward(uint256 amount) external view returns (int256);
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