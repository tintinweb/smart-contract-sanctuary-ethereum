// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { SafeCastUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";

import { TrancheData, TrancheDataHelpers, BondHelpers } from "./_utils/BondHelpers.sol";

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { ITranche } from "./_interfaces/buttonwood/ITranche.sol";
import { IBondController } from "./_interfaces/buttonwood/IBondController.sol";
import { IPerpetualTranche } from "./_interfaces/IPerpetualTranche.sol";

/**
 *  @title RouterV1
 *
 *  @notice Contract to dry-run and batch multiple operations.
 *
 */
contract RouterV1 {
    // math
    using SafeCastUpgradeable for uint256;

    // data handling
    using BondHelpers for IBondController;
    using TrancheDataHelpers for TrancheData;

    // ERC20 operations
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeERC20Upgradeable for ITranche;
    using SafeERC20Upgradeable for IPerpetualTranche;

    modifier afterPerpStateUpdate(IPerpetualTranche perp) {
        perp.updateState();
        _;
    }

    /// @notice Calculates the amount of tranche tokens minted after depositing into the deposit bond.
    /// @dev Used by off-chain services to preview a tranche operation.
    /// @param perp Address of the perp contract.
    /// @param collateralAmount The amount of collateral the user wants to tranche.
    /// @return bond The address of the current deposit bond.
    /// @return trancheAmts The tranche token amounts minted.
    function previewTranche(IPerpetualTranche perp, uint256 collateralAmount)
        external
        afterPerpStateUpdate(perp)
        returns (
            IBondController,
            ITranche[] memory,
            uint256[] memory
        )
    {
        IBondController bond = perp.getDepositBond();

        TrancheData memory td;
        uint256[] memory trancheAmts;
        (td, trancheAmts, ) = bond.previewDeposit(collateralAmount);

        return (bond, td.tranches, trancheAmts);
    }

    /// @notice Calculates the amount of perp tokens minted and fees for the operation.
    /// @dev Used by off-chain services to preview a deposit operation.
    /// @param perp Address of the perp contract.
    /// @param trancheIn The address of the tranche token to be deposited.
    /// @param trancheInAmt The amount of tranche tokens deposited.
    /// @return mintAmt The amount of perp tokens minted.
    /// @return feeToken The address of the fee token.
    /// @return mintFee The fee charged for minting.
    function previewDeposit(
        IPerpetualTranche perp,
        ITranche trancheIn,
        uint256 trancheInAmt
    )
        external
        afterPerpStateUpdate(perp)
        returns (
            uint256,
            IERC20Upgradeable,
            int256
        )
    {
        uint256 mintAmt = perp.computeMintAmt(trancheIn, trancheInAmt);
        IERC20Upgradeable feeToken = perp.feeToken();
        (int256 reserveFee, uint256 protocolFee) = perp.feeStrategy().computeMintFees(mintAmt);
        int256 mintFee = reserveFee + protocolFee.toInt256();
        return (mintAmt, feeToken, mintFee);
    }

    /// @notice Tranches the collateral using the current deposit bond and then deposits individual tranches
    ///         to mint perp tokens. It transfers the perp tokens back to the
    ///         transaction sender along with any unused tranches and fees.
    /// @param perp Address of the perp contract.
    /// @param bond Address of the deposit bond.
    /// @param collateralAmount The amount of collateral the user wants to tranche.
    /// @param feePaid The fee paid to the perp contract to mint perp when the fee token is not the perp token itself, otherwise 0.
    /// @dev Fee to be paid should be pre-computed off-chain using the preview function.
    function trancheAndDeposit(
        IPerpetualTranche perp,
        IBondController bond,
        uint256 collateralAmount,
        uint256 feePaid
    ) external afterPerpStateUpdate(perp) {
        TrancheData memory td = bond.getTrancheData();
        IERC20Upgradeable collateralToken = IERC20Upgradeable(bond.collateralToken());
        IERC20Upgradeable feeToken = perp.feeToken();

        // transfers collateral & fees to router
        collateralToken.safeTransferFrom(msg.sender, address(this), collateralAmount);
        if (feePaid > 0) {
            feeToken.safeTransferFrom(msg.sender, address(this), feePaid);
        }

        // approves collateral to be tranched
        _checkAndApproveMax(collateralToken, address(bond), collateralAmount);

        // tranches collateral
        bond.deposit(collateralAmount);

        // approves fee to be spent to mint perp tokens
        _checkAndApproveMax(feeToken, address(perp), feePaid);

        for (uint8 i = 0; i < td.trancheCount; i++) {
            uint256 trancheAmt = td.tranches[i].balanceOf(address(this));
            uint256 mintAmt = perp.computeMintAmt(td.tranches[i], trancheAmt);
            if (mintAmt > 0) {
                // approves tranches to be spent
                _checkAndApproveMax(td.tranches[i], address(perp), trancheAmt);

                // mints perp tokens using tranches
                perp.deposit(td.tranches[i], trancheAmt);
            } else {
                // transfers unused tranches back
                td.tranches[i].safeTransfer(msg.sender, trancheAmt);
            }
        }

        // transfers any remaining collateral tokens back
        uint256 collateralBalance = collateralToken.balanceOf(address(this));
        if (collateralBalance > 0) {
            collateralToken.safeTransfer(msg.sender, collateralBalance);
        }

        // transfers remaining fee back if overpaid or reward
        uint256 feeBalance = feeToken.balanceOf(address(this));
        if (feeBalance > 0) {
            feeToken.safeTransfer(msg.sender, feeBalance);
        }

        // transfers perp tokens back
        perp.safeTransfer(msg.sender, perp.balanceOf(address(this)));
    }

    /// @notice Calculates the reserve tokens that can be redeemed from the queue
    ///         for burning up to the requested amount of perp tokens.
    /// @dev Used by off-chain services to preview a redeem operation.
    /// @param perp Address of the perp contract.
    /// @param perpAmtBurnt The amount of perp tokens requested to be burnt.
    /// @return reserveTokens The list of reserve tokens redeemed.
    /// @return redemptionAmts The list of reserve token amounts redeemed.
    /// @return feeToken The address of the fee token.
    /// @return burnFee The fee charged for burning.
    function previewRedeem(IPerpetualTranche perp, uint256 perpAmtBurnt)
        external
        afterPerpStateUpdate(perp)
        returns (
            IERC20Upgradeable[] memory,
            uint256[] memory,
            IERC20Upgradeable,
            int256
        )
    {
        (IERC20Upgradeable[] memory reserveTokens, uint256[] memory redemptionAmts) = perp.computeRedemptionAmts(
            perpAmtBurnt
        );
        (int256 reserveFee, uint256 protocolFee) = perp.feeStrategy().computeBurnFees(perpAmtBurnt);
        int256 burnFee = reserveFee + protocolFee.toInt256();
        IERC20Upgradeable feeToken = perp.feeToken();
        return (reserveTokens, redemptionAmts, feeToken, burnFee);
    }

    /// @notice Calculates the amount tranche tokens that can be rolled out, remainders and fees,
    ///         with a given tranche token rolled in and amount.
    /// @dev Used by off-chain services to preview a rollover operation.
    /// @param perp Address of the perp contract.
    /// @param trancheIn The tranche token deposited.
    /// @param tokenOut The reserve token requested to be withdrawn.
    /// @param trancheInAmtRequested The amount of trancheIn tokens available to deposit.
    /// @param maxTokenOutAmtUsed The token balance to be used for rollover.
    /// @dev Set maxTokenOutAmtUsed to max(uint256) to use the entire balance.
    /// @return r The amounts rolled over and remaining.
    /// @return feeToken The address of the fee token.
    /// @return rolloverFee The fee paid by the caller.
    function previewRollover(
        IPerpetualTranche perp,
        ITranche trancheIn,
        IERC20Upgradeable tokenOut,
        uint256 trancheInAmtRequested,
        uint256 maxTokenOutAmtUsed
    )
        external
        afterPerpStateUpdate(perp)
        returns (
            IPerpetualTranche.RolloverPreview memory,
            IERC20Upgradeable,
            int256
        )
    {
        IPerpetualTranche.RolloverPreview memory r;
        r.remainingTrancheInAmt = trancheInAmtRequested;

        IERC20Upgradeable feeToken = perp.feeToken();
        int256 reserveFee = 0;
        uint256 protocolFee = 0;
        if (perp.isAcceptableRollover(trancheIn, tokenOut)) {
            r = perp.computeRolloverAmt(trancheIn, tokenOut, trancheInAmtRequested, maxTokenOutAmtUsed);
            (reserveFee, protocolFee) = perp.feeStrategy().computeRolloverFees(r.perpRolloverAmt);
        }
        int256 rolloverFee = reserveFee + protocolFee.toInt256();
        return (r, feeToken, rolloverFee);
    }

    struct RolloverBatch {
        ITranche trancheIn;
        IERC20Upgradeable tokenOut;
        uint256 trancheInAmt;
    }

    /// @notice Tranches collateral and performs a batch rollover.
    /// @param perp Address of the perp contract.
    /// @param bond Address of the deposit bond.
    /// @param collateralAmount The amount of collateral the user wants to tranche.
    /// @param rollovers List of batch rollover operations pre-computed off-chain.
    /// @param feePaid The fee paid by the user performing rollover (fee could be negative).
    function trancheAndRollover(
        IPerpetualTranche perp,
        IBondController bond,
        uint256 collateralAmount,
        RolloverBatch[] calldata rollovers,
        uint256 feePaid
    ) external afterPerpStateUpdate(perp) {
        TrancheData memory td = bond.getTrancheData();
        IERC20Upgradeable collateralToken = IERC20Upgradeable(bond.collateralToken());
        IERC20Upgradeable feeToken = perp.feeToken();

        // transfers collateral & fees to router
        collateralToken.safeTransferFrom(msg.sender, address(this), collateralAmount);
        if (feePaid > 0) {
            feeToken.safeTransferFrom(msg.sender, address(this), feePaid);
        }

        // approves collateral to be tranched
        _checkAndApproveMax(collateralToken, address(bond), collateralAmount);

        // tranches collateral
        bond.deposit(collateralAmount);

        // approves fee to be spent to rollover
        if (feePaid > 0) {
            _checkAndApproveMax(feeToken, address(perp), feePaid);
        }

        for (uint256 i = 0; i < rollovers.length; i++) {
            // approve trancheIn to be spent by perp
            _checkAndApproveMax(rollovers[i].trancheIn, address(perp), rollovers[i].trancheInAmt);

            // perform rollover
            perp.rollover(rollovers[i].trancheIn, rollovers[i].tokenOut, rollovers[i].trancheInAmt);
        }

        for (uint256 i = 0; i < rollovers.length; i++) {
            // transfer remaining tokenOut tokens back
            uint256 tokenOutBalance = rollovers[i].tokenOut.balanceOf(address(this));
            if (tokenOutBalance > 0) {
                rollovers[i].tokenOut.safeTransfer(msg.sender, tokenOutBalance);
            }
        }

        // transfers unused tranches back
        for (uint8 i = 0; i < td.trancheCount; i++) {
            uint256 trancheBalance = td.tranches[i].balanceOf(address(this));
            if (trancheBalance > 0) {
                td.tranches[i].safeTransfer(msg.sender, trancheBalance);
            }
        }

        // transfers any remaining collateral tokens back
        uint256 collateralBalance = collateralToken.balanceOf(address(this));
        if (collateralBalance > 0) {
            collateralToken.safeTransfer(msg.sender, collateralBalance);
        }

        // transfers remaining fee back if overpaid or reward
        uint256 feeBalance = feeToken.balanceOf(address(this));
        if (feeBalance > 0) {
            feeToken.safeTransfer(msg.sender, feeBalance);
        }
    }

    /// @dev Checks if the spender has sufficient allowance. If not, approves the maximum possible amount.
    function _checkAndApproveMax(
        IERC20Upgradeable token,
        address spender,
        uint256 amount
    ) private {
        uint256 allowance = token.allowance(address(this), spender);
        if (allowance < amount) {
            token.safeApprove(spender, type(uint256).max);
        }
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

    function trancheTokenAddresses(ITranche token) external view returns (bool);

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