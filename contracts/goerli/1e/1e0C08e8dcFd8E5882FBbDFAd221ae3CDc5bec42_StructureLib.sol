// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

// external libraries
import {CashActionUtil} from "grappa/libraries/CashActionUtil.sol";
import {PhysicalActionUtil} from "pomace/libraries/PhysicalActionUtil.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {SafeERC20} from "openzeppelin/token/ERC20/utils/SafeERC20.sol";

// interfaces
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {IHashnoteVault} from "../interfaces/IHashnoteVault.sol";
import {IMarginEngineCash, IMarginEnginePhysical} from "../interfaces/IMarginEngine.sol";

import {ActionArgs as GrappaActionArgs} from "grappa/config/types.sol";
import {ActionArgs as PomaceActionArgs} from "pomace/config/types.sol";

import "../config/constants.sol";
import "../config/errors.sol";
import "../config/types.sol";

library StructureLib {
    using SafeERC20 for IERC20;

    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/
    event WithdrewCollateral(uint256[] amounts, address indexed manager);

    /**
     * @notice verifies that initial collaterals are present (non-zero)
     * @param collaterals is the array of collaterals passed from initParams in initializer
     */
    function verifyInitialCollaterals(Collateral[] calldata collaterals) external pure {
        unchecked {
            for (uint256 i; i < collaterals.length; ++i) {
                if (collaterals[i].id == 0) revert OV_BadCollateral();
            }
        }
    }

    /**
     * @notice Settles the vaults position(s) in grappa.
     * @param marginEngine is the address of the grappa margin engine contract
     */
    function settleOptions(IMarginEngineCash marginEngine) external {
        GrappaActionArgs[] memory actions = new GrappaActionArgs[](1);

        actions[0] = CashActionUtil.createSettleAction();

        marginEngine.execute(address(this), actions);
    }

    /**
     * @notice Settles the vaults position(s) in pomace.
     * @param marginEngine is the address of the pomace margin engine contract
     */
    function settleOptions(IMarginEnginePhysical marginEngine) public {
        PomaceActionArgs[] memory actions = new PomaceActionArgs[](1);

        actions[0] = PhysicalActionUtil.createSettleAction();

        marginEngine.execute(address(this), actions);
    }

    /**
     * @notice Deposits collateral into grappa.
     * @param marginEngine is the address of the grappa margin engine contract
     */
    function depositCollateral(IMarginEngineCash marginEngine, Collateral[] calldata collaterals) external {
        GrappaActionArgs[] memory actions;

        // iterates over collateral balances and creates a withdraw action for each
        for (uint256 i; i < collaterals.length;) {
            IERC20 collateral = IERC20(collaterals[i].addr);

            uint256 balance = collateral.balanceOf(address(this));

            if (balance > 0) {
                collateral.safeApprove(address(marginEngine), balance);

                actions = CashActionUtil.append(
                    actions, CashActionUtil.createAddCollateralAction(collaterals[i].id, balance, address(this))
                );
            }

            unchecked {
                ++i;
            }
        }

        if (actions.length > 0) marginEngine.execute(address(this), actions);
    }

    /**
     * @notice Deposits collateral into pomace.
     * @param marginEngine is the address of the pomace margin engine contract
     */
    function depositCollateral(IMarginEnginePhysical marginEngine, Collateral[] calldata collaterals) external {
        PomaceActionArgs[] memory actions;

        // iterates over collateral balances and creates a withdraw action for each
        for (uint256 i; i < collaterals.length;) {
            IERC20 collateral = IERC20(collaterals[i].addr);

            uint256 balance = collateral.balanceOf(address(this));

            if (balance > 0) {
                collateral.safeApprove(address(marginEngine), balance);

                actions = PhysicalActionUtil.append(
                    actions, PhysicalActionUtil.createAddCollateralAction(collaterals[i].id, balance, address(this))
                );
            }

            unchecked {
                ++i;
            }
        }

        if (actions.length > 0) marginEngine.execute(address(this), actions);
    }

    /**
     * @notice Withdraws all vault collateral(s) from grappa margin account.
     * @param marginEngine is the interface to the grappa margin engine contract
     */
    function withdrawAllCollateral(IMarginEngineCash marginEngine) external {
        // gets the accounts collateral balances
        (,, Balance[] memory collaterals) = marginEngine.marginAccounts(address(this));

        GrappaActionArgs[] memory actions = new GrappaActionArgs[](collaterals.length);
        uint256[] memory withdrawAmounts = new uint256[](collaterals.length);

        // iterates over collateral balances and creates a withdraw action for each
        for (uint256 i; i < collaterals.length;) {
            actions[i] =
                CashActionUtil.createRemoveCollateralAction(collaterals[i].collateralId, collaterals[i].amount, address(this));

            withdrawAmounts[i] = collaterals[i].amount;

            unchecked {
                ++i;
            }
        }

        marginEngine.execute(address(this), actions);

        emit WithdrewCollateral(withdrawAmounts, msg.sender);
    }

    /**
     * @notice Withdraws all vault collateral(s) from pomace margin account.
     * @param marginEngine is the interface to the pomace engine contract
     */
    function withdrawAllCollateral(IMarginEnginePhysical marginEngine) external {
        // gets the accounts collateral balances
        (,, Balance[] memory collaterals) = marginEngine.marginAccounts(address(this));

        PomaceActionArgs[] memory actions = new PomaceActionArgs[](collaterals.length);
        uint256[] memory withdrawAmounts = new uint256[](collaterals.length);

        // iterates over collateral balances and creates a withdraw action for each
        for (uint256 i; i < collaterals.length;) {
            actions[i] =
                PhysicalActionUtil.createRemoveCollateralAction(collaterals[i].collateralId, collaterals[i].amount, address(this));

            withdrawAmounts[i] = collaterals[i].amount;

            unchecked {
                ++i;
            }
        }

        marginEngine.execute(address(this), actions);

        emit WithdrewCollateral(withdrawAmounts, msg.sender);
    }

    /**
     * @notice Withdraws some of vault collateral(s) from grappa margin account.
     * @param marginEngine is the interface to the grappa margin engine contract
     */
    function withdrawCollaterals(
        IMarginEngineCash marginEngine,
        Collateral[] calldata collaterals,
        uint256[] calldata amounts,
        address recipient
    ) external {
        GrappaActionArgs[] memory actions;

        // iterates over collateral balances and creates a withdraw action for each
        for (uint256 i; i < amounts.length;) {
            if (amounts[i] > 0) {
                actions = CashActionUtil.append(
                    actions, CashActionUtil.createRemoveCollateralAction(collaterals[i].id, amounts[i], recipient)
                );
            }

            unchecked {
                ++i;
            }
        }

        if (actions.length > 0) marginEngine.execute(address(this), actions);
    }

    /**
     * @notice Withdraws some of vault collateral(s) from pomace margin account.
     * @param marginEngine is the interface to the pomace margin engine contract
     */
    function withdrawCollaterals(
        IMarginEnginePhysical marginEngine,
        Collateral[] calldata collaterals,
        uint256[] calldata amounts,
        address recipient
    ) external {
        PomaceActionArgs[] memory actions;

        // iterates over collateral balances and creates a withdraw action for each
        for (uint256 i; i < amounts.length;) {
            if (amounts[i] > 0) {
                actions = PhysicalActionUtil.append(
                    actions, PhysicalActionUtil.createRemoveCollateralAction(collaterals[i].id, amounts[i], recipient)
                );
            }

            unchecked {
                ++i;
            }
        }

        if (actions.length > 0) marginEngine.execute(address(this), actions);
    }

    /**
     * @notice Withdraws assets based on shares from grappa margin account.
     * @dev used to send assets from the margin account to recipient at the end of each round
     * @param marginEngine is the interface to the grappa margin engine contract
     * @param totalSupply is the total amount of outstanding shares
     * @param withdrawShares the number of shares being withdrawn
     * @param recipient is the destination address for the assets
     */
    function withdrawWithShares(IMarginEngineCash marginEngine, uint256 totalSupply, uint256 withdrawShares, address recipient)
        external
        returns (uint256[] memory amounts)
    {
        (,, Balance[] memory collaterals) = marginEngine.marginAccounts(address(this));

        uint256 collateralLength = collaterals.length;

        amounts = new uint256[](collateralLength);
        GrappaActionArgs[] memory actions = new GrappaActionArgs[](collateralLength);

        for (uint256 i; i < collateralLength;) {
            amounts[i] = FixedPointMathLib.mulDivDown(collaterals[i].amount, withdrawShares, totalSupply);

            unchecked {
                actions[i] = CashActionUtil.createRemoveCollateralAction(collaterals[i].collateralId, amounts[i], recipient);
                ++i;
            }
        }

        marginEngine.execute(address(this), actions);
    }

    /**
     * @notice Withdraws assets based on shares from pomace margin account.
     * @dev used to send assets from the margin account to recipient at the end of each round
     * @param marginEngine is the interface to the grappa margin engine contract
     * @param totalSupply is the total amount of outstanding shares
     * @param withdrawShares the number of shares being withdrawn
     * @param recipient is the destination address for the assets
     */
    function withdrawWithShares(
        IMarginEnginePhysical marginEngine,
        uint256 totalSupply,
        uint256 withdrawShares,
        address recipient
    ) external returns (uint256[] memory amounts) {
        (,, Balance[] memory collaterals) = marginEngine.marginAccounts(address(this));

        uint256 collateralLength = collaterals.length;

        amounts = new uint256[](collateralLength);
        PomaceActionArgs[] memory actions = new PomaceActionArgs[](collateralLength);

        for (uint256 i; i < collateralLength;) {
            amounts[i] = FixedPointMathLib.mulDivDown(collaterals[i].amount, withdrawShares, totalSupply);

            unchecked {
                actions[i] = PhysicalActionUtil.createRemoveCollateralAction(collaterals[i].collateralId, amounts[i], recipient);
                ++i;
            }
        }

        marginEngine.execute(address(this), actions);
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
library CashActionUtil {
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
    function createTransferLongAction(uint256 tokenId, uint256 amount, address recipient)
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
    function createTransferShortAction(uint256 tokenId, uint256 amount, address recipient)
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
     * @param recipient address to receive the "split" long option token.
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
        action = ActionArgs({action: ActionType.SettleAccount, data: ""});
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

    // add a function prefixed with test here so forge coverage will ignore this file
    function testChillOnHelper() public {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../config/enums.sol";
import "../config/types.sol";

/**
 * @title libraries to encode action arguments
 * @dev   only used in tests
 */
library PhysicalActionUtil {
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
    function createTransferLongAction(uint256 tokenId, uint256 amount, address recipient)
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
    function createTransferShortAction(uint256 tokenId, uint256 amount, address recipient)
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
    function createExerciseTokenAction(uint256 tokenId, uint256 amount) internal pure returns (ActionArgs memory action) {
        action = ActionArgs({action: ActionType.ExerciseToken, data: abi.encode(tokenId, uint64(amount))});
    }

    /**
     * @dev create action to settle an account
     */
    function createSettleAction() internal pure returns (ActionArgs memory action) {
        action = ActionArgs({action: ActionType.SettleAccount, data: ""});
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

    // add a function prefixed with test here so forge coverage will ignore this file
    function testChillOnHelper() public {}
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

    uint256 internal constant MAX_UINT256 = 2**256 - 1;

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
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // Divide x * y by the denominator.
            z := div(mul(x, y), denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // If x * y modulo the denominator is strictly greater than 0,
            // 1 is added to round up the division of x * y by the denominator.
            z := add(gt(mod(mul(x, y), denominator), 0), div(mul(x, y), denominator))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
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
        /// @solidity memory-safe-assembly
        assembly {
            let y := x // We start y at x, which will help us make our initial estimate.

            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // We check y >= 2^(k + 8) but shift right by k bits
            // each branch to ensure that if x >= 256, then y >= 256.
            if iszero(lt(y, 0x10000000000000000000000000000000000)) {
                y := shr(128, y)
                z := shl(64, z)
            }
            if iszero(lt(y, 0x1000000000000000000)) {
                y := shr(64, y)
                z := shl(32, z)
            }
            if iszero(lt(y, 0x10000000000)) {
                y := shr(32, y)
                z := shl(16, z)
            }
            if iszero(lt(y, 0x1000000)) {
                y := shr(16, y)
                z := shl(8, z)
            }

            // Goal was to get z*z*y within a small factor of x. More iterations could
            // get y in a tighter range. Currently, we will have y in [256, 256*2^16).
            // We ensured y >= 256 so that the relative difference between y and y+1 is small.
            // That's not possible if x < 256 but we can just verify those cases exhaustively.

            // Now, z*z*y <= x < z*z*(y+1), and y <= 2^(16+8), and either y >= 256, or x < 256.
            // Correctness can be checked exhaustively for x < 256, so we assume y >= 256.
            // Then z*sqrt(y) is within sqrt(257)/sqrt(256) of sqrt(x), or about 20bps.

            // For s in the range [1/256, 256], the estimate f(s) = (181/1024) * (s+1) is in the range
            // (1/2.84 * sqrt(s), 2.84 * sqrt(s)), with largest error when s = 1 and when s = 256 or 1/256.

            // Since y is in [256, 256*2^16), let a = y/65536, so that a is in [1/256, 256). Then we can estimate
            // sqrt(y) using sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2^18.

            // There is no overflow risk here since y < 2^136 after the first branch above.
            z := shr(18, mul(z, add(y, 65536))) // A mul() is saved from starting z at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If x+1 is a perfect square, the Babylonian method cycles between
            // floor(sqrt(x)) and ceil(sqrt(x)). This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
    }

    function unsafeMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Mod x by y. Note this will return
            // 0 instead of reverting if y is zero.
            z := mod(x, y)
        }
    }

    function unsafeDiv(uint256 x, uint256 y) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            // Divide x by y. Note this will return
            // 0 instead of reverting if y is zero.
            r := div(x, y)
        }
    }

    function unsafeDivUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Add 1 to x * y if x % y > 0. Note this will
            // return 0 instead of reverting if y is zero.
            z := add(gt(mod(x, y), 0), div(x, y))
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IMarginEnginePhysical} from "./IMarginEngine.sol";
import {IVaultShare} from "./IVaultShare.sol";

import "../config/types.sol";

interface IHashnoteVault {
    function share() external view returns (IVaultShare);

    function roundExpiry(uint256 round) external view returns (uint256);

    function whitelist() external view returns (address);

    function vaultState() external view returns (VaultState memory);

    function depositFor(uint256 amount, address creditor) external;

    function requestWithdraw(uint256 numShares) external;

    function getCollaterals() external view returns (Collateral[] memory);

    function depositReceipts(address depositor) external view returns (DepositReceipt memory);

    function redeemFor(address depositor, uint256 numShares, bool isMax) external;

    function managementFee() external view returns (uint256);

    function feeRecipient() external view returns (address);
}

interface IHashnotePhysicalOptionsVault is IHashnoteVault {
    function marginEngine() external view returns (IMarginEnginePhysical);

    function burnSharesFor(address depositor, uint256 sharesToWithdraw) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IGrappa} from "grappa/interfaces/IGrappa.sol";
import {IPomace} from "pomace/interfaces/IPomace.sol";

import {BatchExecute as GrappaBatchExecute, ActionArgs as GrappaActionArgs} from "grappa/config/types.sol";
import {BatchExecute as PomaceBatchExecute, ActionArgs as PomaceActionArgs} from "pomace/config/types.sol";
import "../config/types.sol";

interface IMarginEngine {
    function optionToken() external view returns (address);

    function marginAccounts(address)
        external
        view
        returns (Position[] memory shorts, Position[] memory longs, Balance[] memory collaterals);

    function previewMinCollateral(Position[] memory shorts, Position[] memory longs) external view returns (Balance[] memory);

    function allowedExecutionLeft(uint160 mask, address account) external view returns (uint256);

    function setAccountAccess(address account, uint256 allowedExecutions) external;

    function revokeSelfAccess(address granter) external;
}

interface IMarginEngineCash is IMarginEngine {
    function grappa() external view returns (IGrappa grappa);

    function execute(address account, GrappaActionArgs[] calldata actions) external;

    function batchExecute(GrappaBatchExecute[] calldata batchActions) external;
}

interface IMarginEnginePhysical is IMarginEngine {
    function pomace() external view returns (IPomace pomace);

    function execute(address account, PomaceActionArgs[] calldata actions) external;

    function batchExecute(PomaceBatchExecute[] calldata batchActions) external;
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

import "./enums.sol";

/**
 * @dev struct representing the current balance for a given collateral
 * @param collateralId pomace asset id
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

///@dev unit scaled used to convert amounts.
uint256 constant UNIT = 10 ** 6;

// Placeholder uint value to prevent cold writes
uint256 constant PLACEHOLDER_UINT = 1;

// Fees are 18-decimal places. For example: 20 * 10**18 = 20%
uint256 constant PERCENT_MULTIPLIER = 10 ** 18;

uint32 constant SECONDS_PER_DAY = 86400;
uint32 constant DAYS_PER_YEAR = 365;

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

// common
error Unauthorized();
error Overflow();
error BadAddress();

// BaseVault
error BV_ActiveRound();
error BV_BadCollateral();
error BV_BadExpiry();
error BV_BadLevRatio();
error BV_ExpiryMismatch();
error BV_MarginEngineMismatch();
error BV_RoundClosed();
error BV_BadFee();
error BV_BadRoundConfig();
error BV_BadDepositAmount();
error BV_BadAmount();
error BV_BadRound();
error BV_BadNumShares();
error BV_ExceedsAvailable();
error BV_BadPPS();
error BV_BadSB();
error BV_BadCP();
error BV_BadRatios();

// OptionsVault
error OV_ActiveRound();
error OV_BadRound();
error OV_BadCollateral();
error OV_RoundClosed();
error OV_OptionNotExpired();
error OV_NoCollateralPending();
error OV_VaultExercised();

// PhysicalOptionVault
error POV_CannotRequestWithdraw();
error POV_NotExercised();
error POV_NoCollateral();
error POV_OptionNotExpired();
error POV_BadExerciseWindow();

// Fee Utils
error FL_NPSLow();

// Vault Utils
error VL_DifferentLengths();
error VL_ExceedsSurplus();
error VL_BadOwnerAddress();
error VL_BadManagerAddress();
error VL_BadFeeAddress();
error VL_BadOracleAddress();
error VL_BadPauserAddress();
error VL_BadFee();
error VL_BadCollateral();
error VL_BadCollateralAddress();
error VL_BadDuration();

// StructureLib
error SL_BadExpiryDate();

// Vault Pauser
error VP_VaultNotPermissioned();
error VP_PositionPaused();
error VP_Overflow();
error VP_CustomerNotPermissioned();
error VP_RoundOpen();

// Vault Share
error VS_SupplyExceeded();

// Whitelist Manager
error WL_BadRole();
error WL_Paused();

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

/**
 * @notice Initialization parameters for the vault.
 * @param _owner is the owner of the vault with critical permissions
 * @param _manager is the address that is responsible for advancing the vault
 * @param _feeRecipient is the address to receive vault performance and management fees
 * @param _oracle is used to calculate NAV
 * @param _whitelist is used to check address access permissions
 * @param _managementFee is the management fee pct.
 * @param _performanceFee is the performance fee pct.
 * @param _pauser is where withdrawn collateral exists waiting for client to withdraw
 * @param _collateralRatios is the array of round starting balances to set the initial collateral ratios
 * @param _collaterals is the assets used in the vault
 * @param _roundConfig sets the duration and expiration of options
 * @param _vaultParams set vaultParam struct
 */
struct InitParams {
    address _owner;
    address _manager;
    address _feeRecipient;
    address _oracle;
    address _whitelist;
    uint256 _managementFee;
    uint256 _performanceFee;
    address _pauser;
    uint256[] _collateralRatios;
    Collateral[] _collaterals;
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

struct VaultState {
    // 32 byte slot 1
    // Round represents the number of periods elapsed. There's a hard limit of 4,294,967,295 rounds
    uint32 round;
    // Amount that is currently locked for selling options
    uint96 lockedAmount;
    // Amount that was locked for selling options in the previous round
    // used for calculating performance fee deduction
    uint96 lastLockedAmount;
    // 32 byte slot 2
    // Stores the total tally of how much of `asset` there is
    // to be used to mint vault tokens
    uint96 totalPending;
    // store the number of shares queued for withdraw this round
    // zero'ed out at the start of each round, pauser withdraws all queued shares.
    uint128 queuedWithdrawShares;
}

struct DepositReceipt {
    // Round represents the number of periods elapsed. There's a hard limit of 4,294,967,295 rounds
    uint32 round;
    // Deposit amount, max 79,228,162,514 or 79 Billion ETH deposit
    uint96 amount;
    // Unredeemed shares balance
    uint128 unredeemedShares;
}

struct RoundConfig {
    // the duration of the option
    uint32 duration;
    // day of the week the option should expire. 0-8, 0 is sunday, 7 is sunday, 8 is wild
    uint8 dayOfWeek;
    // hour of the day the option should expire. 0 is midnight
    uint8 hourOfDay;
}

// Used for fee calculations at the end of a round
struct VaultDetails {
    // Collaterals of the vault
    Collateral[] collaterals;
    // Collateral balances at the start of the round
    uint256[] roundStartingBalances;
    // current balances
    uint256[] currentBalances;
    // Total pending primary asset
    uint256 totalPending;
}

// Used when rolling funds into a new round
struct NAVDetails {
    // Collaterals of the vault
    Collateral[] collaterals;
    // Collateral balances at the start of the round
    uint256[] startingBalances;
    // Current collateral balances
    uint256[] currentBalances;
    // Used to calculate NAV
    address oracleAddr;
    // Expiry of the round
    uint256 expiry;
    // Pending deposits
    uint256 totalPending;
}

/**
 * @dev Position struct
 * @param tokenId option token id
 * @param amount number option tokens
 */
struct Position {
    uint256 tokenId;
    uint64 amount;
}

/**
 * @dev struct representing the current balance for a given collateral
 * @param collateralId asset id
 * @param amount amount the asset
 */
struct Balance {
    uint8 collateralId;
    uint80 amount;
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
 * @dev common action types on margin engines
 */
enum ActionType {
    AddCollateral,
    RemoveCollateral,
    MintShort,
    BurnShort,
    MergeOptionToken, // These actions are defined in "DebitSpread"
    SplitOptionToken, // These actions are defined in "DebitSpread"
    AddLong,
    RemoveLong,
    SettleAccount,
    // actions that influence more than one subAccounts:
    // These actions are defined in "OptionTransferable"
    MintShortIntoAccount, // increase short (debt) position in one subAccount, increase long token directly to another subAccount
    TransferCollateral, // transfer collateral directly to another subAccount
    TransferLong, // transfer long directly to another subAccount
    TransferShort // transfer short directly to another subAccount
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

enum TokenType {
    PUT,
    CALL
}

/**
 * @dev common action types on margin engines
 */
enum ActionType {
    AddCollateral,
    RemoveCollateral,
    MintShort,
    BurnShort,
    AddLong,
    RemoveLong,
    ExerciseToken,
    SettleAccount,
    // actions that influence more than one subAccounts:
    // These actions are defined in "OptionTransferable"
    MintShortIntoAccount, // increase short (debt) position in one subAccount, increase long token directly to another subAccount
    TransferCollateral, // transfer collateral directly to another subAccount
    TransferLong, // transfer long directly to another subAccount
    TransferShort // transfer short directly to another subAccount
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IVaultShare {
    /**
     * @dev mint option token to an address. Can only be called by corresponding vault
     * @param _recipient    where to mint token to
     * @param _amount       amount to mint
     *
     */
    function mint(address _recipient, uint256 _amount) external;

    /**
     * @dev burn option token from an address. Can only be called by corresponding vault
     * @param _from         account to burn from
     * @param _amount       amount to burn
     *
     */
    function burn(address _from, uint256 _amount) external;

    /**
     * @dev burn option token from addresses. Can only be called by corresponding vault
     * @param _froms        accounts to burn from
     * @param _amounts      amounts to burn
     *
     */
    function batchBurn(address[] memory _froms, uint256[] memory _amounts) external;

    /**
     * @dev returns total supply of a vault
     * @param _vault      address of the vault
     *
     */
    function totalSupply(address _vault) external view returns (uint256 amount);

    /**
     * @dev returns vault share balance for a given holder
     * @param _owner      address of token holder
     * @param _vault      address of the vault
     *
     */
    function getBalanceOf(address _owner, address _vault) external view returns (uint256 amount);

    /**
     * @dev exposing transfer method to vault
     *
     */
    function transferVaultOnly(address _from, address _to, uint256 _amount, bytes calldata _data) external;

    /**
     * @dev helper metod to pass in vault address instead of tokenId
     *
     */
    function transferFromWithVault(address _from, address _to, address _vault, uint256 _amount, bytes calldata _data) external;
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

    function assetIds(address _asset) external view returns (uint8 id);

    function assets(uint8 _id) external view returns (address addr, uint8 decimals);

    function engines(uint8 _id) external view returns (address engine);

    function oracles(uint8 _id) external view returns (address oracle);

    function getPayout(uint256 tokenId, uint64 amount)
        external
        view
        returns (address engine, address collateral, uint256 payout);

    function getProductId(address oracle, address engine, address underlying, address strike, address collateral)
        external
        view
        returns (uint40 id);

    function getTokenId(TokenType tokenType, uint40 productId, uint256 expiry, uint256 longStrike, uint256 shortStrike)
        external
        view
        returns (uint256 id);

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

import "../config/types.sol";
import {IOracle} from "./IOracle.sol";

interface IPomace {
    function oracle() external view returns (IOracle oracle);

    function checkEngineAccess(uint256 _tokenId, address _engine) external view;

    function checkEngineAccessAndTokenId(uint256 _tokenId, address _engine) external view;

    function engineIds(address _engine) external view returns (uint8 id);

    function assetIds(address _asset) external view returns (uint8 id);

    function assets(uint8 _id) external view returns (address addr, uint8 decimals);

    function engines(uint8 _id) external view returns (address engine);

    function isCollateralizable(uint8 _asset0, uint8 _asset1) external view returns (bool);

    function isCollateralizable(address _asset0, address _asset1) external view returns (bool);

    function getDebtAndPayout(uint256 tokenId, uint64 amount)
        external
        view
        returns (address engine, uint8 debtId, uint256 debt, uint8 payoutId, uint256 payout);

    function batchGetDebtAndPayouts(uint256[] calldata tokenId, uint256[] calldata amount)
        external
        view
        returns (Balance[] memory debts, Balance[] memory payouts);

    function getProductId(address engine, address underlying, address strike, address collateral)
        external
        view
        returns (uint32 id);

    function getTokenId(TokenType tokenType, uint32 productId, uint256 expiry, uint256 strike, uint256 exerciseWindow)
        external
        view
        returns (uint256 id);

    function getDetailFromProductId(uint32 _productId)
        external
        view
        returns (
            address engine,
            address underlying,
            uint8 underlyingDecimals,
            address strike,
            uint8 strikeDecimals,
            address collateral,
            uint8 collateralDecimals
        );

    /**
     * @notice burn option token and get out cash value at expiry
     * @param _account who to settle for
     * @param _tokenId  tokenId of option token to burn
     * @param _amount   amount to settle
     * @return debt amount collected
     * @return payout amount paid out
     */
    function settleOption(address _account, uint256 _tokenId, uint256 _amount)
        external
        returns (Balance memory debt, Balance memory payout);

    /**
     * @notice burn array of option tokens and get out cash value at expiry
     * @param _account who to settle for
     * @param _tokenIds array of tokenIds to burn
     * @param _amounts   array of amounts to burn
     */
    function batchSettleOptions(address _account, uint256[] memory _tokenIds, uint256[] memory _amounts) external;
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