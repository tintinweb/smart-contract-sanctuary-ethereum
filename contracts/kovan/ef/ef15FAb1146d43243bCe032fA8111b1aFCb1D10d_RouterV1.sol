// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { TrancheData, BondHelpers, TrancheDataHelpers } from "./_utils/BondHelpers.sol";

import { MintData, BurnData, RolloverData, IPerpetualTranche } from "./_interfaces/IPerpetualTranche.sol";
import { IBondController } from "./_interfaces/buttonwood/IBondController.sol";
import { ITranche } from "./_interfaces/buttonwood/ITranche.sol";

/*
 *  @title RouterV1
 *
 *  @notice Contract to batch multiple operations.
 *
 */
contract RouterV1 {
    using SafeERC20 for IERC20;
    using SafeERC20 for ITranche;
    using SafeERC20 for IPerpetualTranche;
    using BondHelpers for IBondController;
    using TrancheDataHelpers for TrancheData;

    function bond(ITranche t) public view returns (address) {
        return t.bond();
    }

    function trancheData(IBondController bond) public view returns (TrancheData memory) {
        return bond.getTrancheData();
    }

    function trancheCount(IBondController bond) public view returns (uint256) {
        return bond.trancheCount();
    }

    function tranche(IBondController bond, uint256 index) public view returns (ITranche, uint256) {
        return bond.tranches(index);
    }

    // @notice Given collateral amount the function calculates the amount of perp tokens
    //  that can be minted and fees for the operation.
    // @dev Used by off-chain services to estimate a batch tranche, deposit operation.
    // @param b The address of the bond contract.
    // @return The amount minted and fee charged.
    function trancheAndDepositPreview(IPerpetualTranche perp, uint256 collateralAmount)
        external
        returns (MintData memory totalMintData)
    {
        IBondController bond = perp.getMintingBond();
        (TrancheData memory td, uint256[] memory trancheAmts, ) = bond.previewDeposit(collateralAmount);

        for (uint8 i = 0; i < td.trancheCount; i++) {
            ITranche t = td.tranches[i];
            MintData memory trancheMintData = perp.previewDeposit(t, trancheAmts[i]);
            totalMintData.amount += trancheMintData.amount;
            totalMintData.fee += trancheMintData.fee;
        }
        return totalMintData;
    }

    // @notice Given collateral and fees, the function tranches the collateral
    //         using the current minting bond and then deposits individual tranches
    //         to mint perp tokens. It transfers the perp tokens back to the
    //         transaction sender along with, any unused tranches and fees.
    // @param perp Address of the perpetual tranche contract.
    // @param collateralAmount The amount of collateral the user wants to tranche.
    // @param fee The fee paid to the perpetual tranche contract to mint perp.
    function trancheAndDeposit(
        IPerpetualTranche perp,
        uint256 collateralAmount,
        uint256 fee
    ) external {
        IBondController bond = perp.getMintingBond();
        TrancheData memory td = bond.getTrancheData();

        IERC20 collateralToken = IERC20(bond.collateralToken());
        IERC20 feeToken = perp.feeToken();

        // transfer collateral & fee to router
        collateralToken.safeTransferFrom(msg.sender, address(this), collateralAmount);
        if (fee > 0) {
            feeToken.safeTransferFrom(msg.sender, address(this), fee);
        }

        // NOTE: we use _checkAndApproveMax instead of _approveAll here as AMPL
        // does not support infinite approvals.
        _checkAndApproveMax(collateralToken, address(bond), collateralAmount);

        // tranche collateral
        bond.deposit(collateralAmount);

        // approve fee
        _approveAll(feeToken, address(perp));

        // use tranches to mint perp
        for (uint8 i = 0; i < td.trancheCount; i++) {
            ITranche t = td.tranches[i];
            uint256 mintedTranches = t.balanceOf(address(this));

            uint256 mintedSpot = perp.tranchesToPerps(t, mintedTranches);
            if (mintedSpot > 0) {
                // approve perp to use tranche tokens
                _approveAll(t, address(perp));

                // Mint perp tokens
                perp.deposit(t, mintedTranches);
            } else {
                // tranche unused for minting
                // transfer remaining tranches back to user
                t.safeTransfer(msg.sender, mintedTranches);
            }
        }

        // transfer remaining fee back if overpaid
        feeToken.safeTransfer(msg.sender, feeToken.balanceOf(address(this)));

        // transfer perp back
        perp.safeTransfer(msg.sender, perp.balanceOf(address(this)));
    }

    // @notice Given the perp amount, calculates the tranches that can be redeemed
    //         and fees for the operation.
    // @dev Used by off chain services to dry-run a redeem operation.
    // @param perp Address of the perpetual tranche contract.
    // @return The amount burnt, tranches redeemed and fee charged.
    function redeemTranchesPreview(IPerpetualTranche perp, uint256 amount) external returns (BurnData memory) {
        return perp.previewRedeem(amount);
    }

    // @notice Given perp tokens and fees, the function burns perp and redeems
    //         tranches. If the burn is incomplete, it transfers the remainder back.
    // @param perp Address of the perpetual tranche contract.
    // @param amount The amount of perp tokens the user wants to burn.
    // @param fee The fee paid to the perpetual tranche contract to burn perp tokens.
    function redeemTranches(
        IPerpetualTranche perp,
        uint256 amount,
        uint256 fee
    ) external {
        IERC20 feeToken = perp.feeToken();

        // transfer perp tokens & fee to router
        perp.safeTransferFrom(msg.sender, address(this), amount);
        if (fee > 0) {
            feeToken.safeTransferFrom(msg.sender, address(this), fee);
        }

        // approve perp tokens & fees
        _approveAll(perp, address(perp));
        _approveAll(feeToken, address(perp));

        // burn perp tokens
        BurnData memory b = perp.redeem(amount);
        for (uint256 i = 0; i < b.trancheCount; i++) {
            // transfer redeemed tranches back
            b.tranches[i].safeTransfer(msg.sender, b.trancheAmts[i]);
        }

        // transfer remaining fee back if overpaid
        feeToken.safeTransfer(msg.sender, feeToken.balanceOf(address(this)));

        // transfer remainder back
        perp.safeTransfer(msg.sender, b.remainder);
    }

    // @dev Approves the spender to spend an infinite tokens from the router's balance.
    function _approveAll(IERC20 token, address spender) private {
        _checkAndApproveMax(token, spender, type(uint256).max);
    }

    // @dev Checks if the spender has sufficient allowance if not approves the maximum possible amount.
    function _checkAndApproveMax(
        IERC20 token,
        address spender,
        uint256 amount
    ) private {
        uint256 allowance = token.allowance(address(this), spender);
        if (allowance < amount) {
            token.approve(spender, type(uint256).max);
        }
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
    function trancheYield(ITranche tranche) external view returns (uint256);

    // @notice The price of the given tranche.
    // @param t The address of the tranche token.
    // @return The computed price.
    function tranchePrice(ITranche tranche) external view returns (uint256);

    // @notice Computes the amount of perp token amount that can be exchanged for given tranche and amount.
    // @param t The address of the tranche token.
    // @param trancheAmt The amount of tranche tokens.
    // @return The perp token amount.
    function tranchesToPerps(ITranche tranche, uint256 trancheAmt) external view returns (uint256);

    // @notice Computes the amount of tranche tokens amount that can be exchanged for given perp token amount.
    // @param t The address of the tranche token.
    // @param trancheAmt The amount of perp tokens.
    // @return The tranche token amount.
    function perpsToTranches(ITranche tranche, uint256 amount) external view returns (uint256);

    // @notice Number of tranche tokens held in the reserve.
    function trancheCount() external view returns (uint256);

    // @notice The tranche address from the tranche list at a given index.
    // @param i The index of the tranche list.
    function trancheAt(uint256 i) external view returns (address);
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

interface ITranche is IERC20 {
    function bond() external view returns (address);
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