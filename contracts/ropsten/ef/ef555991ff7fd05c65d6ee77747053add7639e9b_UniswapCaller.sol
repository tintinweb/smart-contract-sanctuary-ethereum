// Copyright (C) 2020 Zerion Inc. <https://zerion.io>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.12;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { ICaller } from "../interfaces/ICaller.sol";
import { IUniswapV2Pair } from "../interfaces/IUniswapV2Pair.sol";
import { IWETH9 } from "../interfaces/IWETH9.sol";
import { Base } from "../shared/Base.sol";
import { SwapType } from "../shared/Enums.sol";
import {
    BadToken,
    InconsistentPairsAndDirectionsLengths,
    InputSlippage,
    LowReserve,
    ZeroAmountIn,
    ZeroAmountOut,
    ZeroLength
} from "../shared/Errors.sol";
import { TokensHandler } from "../shared/TokensHandler.sol";
import { Weth } from "../shared/Weth.sol";

/**
 * @title Uniswap caller that executes swaps on UniswapV2-like pools
 */
contract UniswapCaller is ICaller, TokensHandler, Weth {
    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /**
     * @notice Sets Wrapped Ether address for the current chain
     * @param weth Wrapped Ether address
     */
    constructor(address weth) Weth(weth) {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @notice Main external function:
     *     executes swap using Uniswap-like pools and returns tokens to the account
     * @param callerCallData ABI-encoded parameters:
     *     - inputToken Address of the token that should be spent
     *     - outputToken Address of the token that should be returned
     *     - pairs Array of uniswap-like pairs
     *     - directions Array of exchange directions (`true` means `token0` -> `token1`)
     *     - swapType Whether input or output amount is fixed
     *     - fixedSideAmount Amount of the token which is fixed (see `swapType`)
     *     - unwrap Bool indicating whether Wrapped Ether should be unwrapped to Ether
     * @dev Implementation of Caller interface function
     */
    function callBytes(bytes calldata callerCallData) external override {
        (
            address inputToken,
            address outputToken,
            address[] memory pairs,
            bool[] memory directions,
            SwapType swapType,
            uint256 fixedSideAmount
        ) = abi.decode(callerCallData, (address, address, address[], bool[], SwapType, uint256));

        uint256 length = pairs.length;
        if (length == uint256(0)) revert ZeroLength();
        if (directions.length != length)
            revert InconsistentPairsAndDirectionsLengths(length, directions.length);

        uint256[] memory amounts = (swapType == SwapType.FixedInputs)
            ? getAmountsOut(fixedSideAmount, pairs, directions)
            : getAmountsIn(fixedSideAmount, pairs, directions);

        // Take input tokens and transfer to the first pair
        {
            address token = directions[0]
                ? IUniswapV2Pair(pairs[0]).token0()
                : IUniswapV2Pair(pairs[0]).token1();

            if (inputToken == ETH) {
                depositEth(amounts[0]);
            }

            uint256 balance = IERC20(token).balanceOf(address(this));
            if (amounts[0] > balance) revert InputSlippage(balance, amounts[0]);

            SafeERC20.safeTransfer(IERC20(token), pairs[0], amounts[0]);
        }

        // Do the swaps via the given pairs
        {
            address destination = (outputToken == ETH) ? address(this) : msg.sender;

            for (uint256 i = 0; i < length; i++) {
                uint256 next = i + 1;
                (uint256 amount0Out, uint256 amount1Out) = directions[i]
                    ? (uint256(0), amounts[next])
                    : (amounts[next], uint256(0));
                IUniswapV2Pair(pairs[i]).swap(
                    amount0Out,
                    amount1Out,
                    next < length ? pairs[next] : destination,
                    bytes("")
                );
            }
        }

        // Unwrap weth if necessary
        if (outputToken == ETH) withdrawEth();

        // In case of non-zero input token, transfer the remaining amount back to `msg.sender`
        Base.transfer(inputToken, msg.sender, Base.getBalance(inputToken));

        // In case of non-zero output token, transfer the total balance to `msg.sender`
        Base.transfer(outputToken, msg.sender, Base.getBalance(outputToken));
    }

    /**
     * @notice Wraps Ether
     * @param amount Amount of Ether to be wrapped
     */
    function depositEth(uint256 amount) internal {
        address weth = getWeth();
        IWETH9(weth).deposit{ value: amount }();
    }

    /**
     * @notice Unwraps Wrapped Ether (if necessary)
     */
    function withdrawEth() internal {
        address weth = getWeth();
        uint256 wethBalance = IERC20(weth).balanceOf(address(this));
        // The check always passes, however, left for unusual cases
        if (wethBalance > uint256(0)) IWETH9(weth).withdraw(wethBalance);
    }

    /**
     * @notice Calculates the required amounts for multiple swaps in case of fixed output amount
     * @param amountOut Amount of tokens returned after the last swap
     * @param pairs Array of uniswap-like pairs
     * @param directions Array of exchange directions (`true` means token0 -> token1)
     * @return amountsIn Amounts required for the multiple swaps
     * @dev Performs chained getAmountIn calculations
     */
    function getAmountsIn(
        uint256 amountOut,
        address[] memory pairs,
        bool[] memory directions
    ) internal view returns (uint256[] memory amountsIn) {
        uint256 length = pairs.length;

        amountsIn = new uint256[](length + 1);
        amountsIn[length] = amountOut;

        for (uint256 i = length; i > uint256(0); i--) {
            uint256 prev = i - 1;
            amountsIn[prev] = getAmountIn(amountsIn[i], pairs[prev], directions[prev]);
        }

        return amountsIn;
    }

    /**
     * @notice Calculates the return amounts for multiple swaps in case of fixed input amount
     * @param amountIn Amount of tokens provided for the first swap
     * @param pairs Array of uniswap-like pairs
     * @param directions Array of exchange directions (`true` means token0 -> token1)
     * @return amountsOut Amounts returned after the multiple swaps
     * @dev Performs chained getAmountOut calculations
     */
    function getAmountsOut(
        uint256 amountIn,
        address[] memory pairs,
        bool[] memory directions
    ) internal view returns (uint256[] memory amountsOut) {
        uint256 length = pairs.length;

        amountsOut = new uint256[](length + 1);
        amountsOut[0] = amountIn;

        for (uint256 i = 0; i < length; i++) {
            amountsOut[i + 1] = getAmountOut(amountsOut[i], pairs[i], directions[i]);
        }

        return amountsOut;
    }

    /**
     * @notice Calculates the required amount for one swap in case of fixed output amount
     * @param amountOut Amount of the token returned after the swap
     * @param pair Uniswap-like pair
     * @param direction Exchange direction (`true` means token0 -> token1)
     * @return amountIn Amount required for the swap
     * @dev Repeats Uniswap's getAmountIn calculations
     */
    function getAmountIn(
        uint256 amountOut,
        address pair,
        bool direction
    ) internal view returns (uint256 amountIn) {
        if (amountOut == uint256(0)) revert ZeroAmountOut();

        (uint256 reserveIn, uint256 reserveOut) = getReserves(pair, direction);
        if (reserveOut < amountOut) revert LowReserve(reserveOut, amountOut);

        uint256 numerator = reserveIn * amountOut * 1000;
        uint256 denominator = (reserveOut - amountOut) * 997;

        return (numerator / denominator) + 1;
    }

    /**
     * @notice Calculates the returned amount for one swap in case of fixed input amount
     * @param amountIn Amount of the token provided for the swap
     * @param pair Uniswap-like pair
     * @param direction Exchange direction (`true` means token0 -> token1)
     * @return amountOut Amount returned after the swap
     * @dev Repeats Uniswap's getAmountIn calculations
     */
    function getAmountOut(
        uint256 amountIn,
        address pair,
        bool direction
    ) internal view returns (uint256 amountOut) {
        if (amountIn == uint256(0)) revert ZeroAmountIn();

        (uint256 reserveIn, uint256 reserveOut) = getReserves(pair, direction);

        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = (reserveIn * 1000) + amountInWithFee;

        return numerator / denominator;
    }

    /**
     * @notice Returns pool's reserves in 'correct' order (input token, output token)
     * @param pair Uniswap-like pair
     * @param direction Exchange direction (`true` means token0 -> token1)
     * @return reserveIn Pool reserve for input token
     * @return reserveOut Pool reserve for output token
     */
    function getReserves(address pair, bool direction)
        internal
        view
        returns (uint256 reserveIn, uint256 reserveOut)
    {
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(pair).getReserves();
        (reserveIn, reserveOut) = direction ? (reserve0, reserve1) : (reserve1, reserve0);

        return (reserveIn, reserveOut);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

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

// Copyright (C) 2020 Zerion Inc. <https://zerion.io>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.12;

import { AbsoluteTokenAmount } from "../shared/Structs.sol";

import { ITokensHandler } from "./ITokensHandler.sol";

interface ICaller is ITokensHandler {
    /**
     * @notice Main external function: implements all the caller specific logic
     * @param callerCallData ABI-encoded parameters depending on the caller logic
     */
    function callBytes(bytes calldata callerCallData) external;
}

// Copyright (C) 2020 Zerion Inc. <https://zerion.io>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.12;

/**
 * @dev UniswapV2Pair contract interface.
 * The UniswapV2Pair contract is available here
 * github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2Pair.sol.
 */
interface IUniswapV2Pair {
    function mint(address) external returns (uint256);

    function burn(address) external returns (uint256, uint256);

    function swap(
        uint256,
        uint256,
        address,
        bytes calldata
    ) external;

    function getReserves()
        external
        view
        returns (
            uint112,
            uint112,
            uint32
        );

    function token0() external view returns (address);

    function token1() external view returns (address);
}

// Copyright (C) 2020 Zerion Inc. <https://zerion.io>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.12;

/**
 * @dev WETH9 contract interface.
 * Only the functions required for WethInteractiveAdapter contract are added.
 * The WETH9 contract is available here
 * github.com/0xProject/0x-monorepo/blob/development/contracts/erc20/contracts/src/WETH9.sol.
 */
interface IWETH9 {
    function deposit() external payable;

    function withdraw(uint256) external;

    function balanceOf(address) external view returns (uint256);
}

// Copyright (C) 2020 Zerion Inc. <https://zerion.io>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.12;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";

import { FailedEtherTransfer, ZeroReceiver } from "./Errors.sol";

/**
 * @title Library unifying transfer, approval, and getting balance for ERC20 tokens and Ether
 */
library Base {
    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /**
     * @notice Transfers tokens or Ether
     * @param token Address of the token or `ETH` in case of Ether transfer
     * @param receiver Address of the account that will receive funds
     * @param amount Amount to be transferred
     * @dev This function is compatible only with ERC20 tokens and Ether, not ERC721/ERC1155 tokens
     * @dev Reverts on zero `receiver`, does nothing for zero amount
     * @dev Should not be used with zero token address
     */
    function transfer(
        address token,
        address receiver,
        uint256 amount
    ) internal {
        if (amount == uint256(0)) return;
        if (receiver == address(0)) revert ZeroReceiver();

        if (token == ETH) {
            Address.sendValue(payable(receiver), amount);
        } else {
            SafeERC20.safeTransfer(IERC20(token), receiver, amount);
        }
    }

    /**
     * @notice Safely approves type(uint256).max tokens
     * @param token Address of the token
     * @param spender Address to approve tokens to
     * @param amount Tokens amount to be approved
     * @dev Should not be used with zero or `ETH` token address
     */
    function safeApproveMax(
        address token,
        address spender,
        uint256 amount
    ) internal {
        uint256 allowance = IERC20(token).allowance(address(this), spender);
        if (allowance < amount) {
            if (allowance > uint256(0)) {
                SafeERC20.safeApprove(IERC20(token), spender, uint256(0));
            }
            SafeERC20.safeApprove(IERC20(token), spender, type(uint256).max);
        }
    }

    /**
     * @notice Calculates the token balance for the given account
     * @param token Address of the token
     * @param account Address of the account
     * @dev Should not be used with zero token address
     */
    function getBalance(address token, address account) internal view returns (uint256) {
        if (token == ETH) return account.balance;

        return IERC20(token).balanceOf(account);
    }

    /**
     * @notice Calculates the token balance for `this` contract address
     * @param token Address of the token
     * @dev Returns `0` for zero token address in order to handle empty token case
     */
    function getBalance(address token) internal view returns (uint256) {
        if (token == address(0)) return uint256(0);

        return Base.getBalance(token, address(this));
    }
}

// Copyright (C) 2020 Zerion Inc. <https://zerion.io>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.12;

enum ActionType {
    None,
    Deposit,
    Withdraw
}

enum AmountType {
    None,
    Relative,
    Absolute
}

enum SwapType {
    None,
    FixedInputs,
    FixedOutputs
}

enum PermitType {
    None,
    EIP2612,
    DAI,
    Yearn
}

// Copyright (C) 2020 Zerion Inc. <https://zerion.io>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.12;

import { ActionType, AmountType, PermitType, SwapType } from "./Enums.sol";
import { Fee } from "./Structs.sol";

error BadAccount(address account, address expectedAccount);
error BadAccountSignature();
error BadAmount(uint256 amount, uint256 requiredAmount);
error BadAmountType(AmountType amountType, AmountType requiredAmountType);
error BadFee(Fee fee, Fee baseProtocolFee);
error BadFeeAmount(uint256 actualFeeAmount, uint256 expectedFeeAmount);
error BadFeeSignature();
error BadFeeShare(uint256 protocolFeeShare, uint256 baseProtocolFeeShare);
error BadFeeBeneficiary(address protocolFeeBanaficiary, address baseProtocolFeeBeneficiary);
error BadLength(uint256 length, uint256 requiredLength);
error BadMsgSender(address msgSender, address requiredMsgSender);
error BadProtocolAdapterName(bytes32 protocolAdapterName);
error BadToken(address token);
error ExceedingDelimiterAmount(uint256 amount);
error ExceedingLimitFee(uint256 feeShare, uint256 feeLimit);
error FailedEtherTransfer(address to);
error HighInputBalanceChange(uint256 inputBalanceChange, uint256 requiredInputBalanceChange);
error InconsistentPairsAndDirectionsLengths(uint256 pairsLength, uint256 directionsLength);
error InputSlippage(uint256 amount, uint256 requiredAmount);
error InsufficientAllowance(uint256 allowance, uint256 requiredAllowance);
error InsufficientMsgValue(uint256 msgValue, uint256 requiredMsgValue);
error LowActualOutputAmount(uint256 actualOutputAmount, uint256 requiredActualOutputAmount);
error LowReserve(uint256 reserve, uint256 requiredReserve);
error NoneActionType();
error NoneAmountType();
error NonePermitType();
error NoneSwapType();
error PassedDeadline(uint256 timestamp, uint256 deadline);
error TooLowBaseFeeShare(uint256 baseProtocolFeeShare, uint256 baseProtocolFeeShareLimit);
error UsedHash(bytes32 hash);
error ZeroReceiver();
error ZeroAmountIn();
error ZeroAmountOut();
error ZeroFeeBeneficiary();
error ZeroLength();
error ZeroProtocolAdapterRegistry();
error ZeroSigner();
error ZeroSwapPath();
error ZeroTarget();

// Copyright (C) 2020 Zerion Inc. <https://zerion.io>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.12;

import { ITokensHandler } from "../interfaces/ITokensHandler.sol";

import { Base } from "./Base.sol";
import { Ownable } from "./Ownable.sol";

/**
 * @title Abstract contract returning tokens lost on the contract
 */
abstract contract TokensHandler is ITokensHandler, Ownable {
    receive() external payable {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @inheritdoc ITokensHandler
     */
    function returnLostTokens(address token, address payable beneficiary) external onlyOwner {
        Base.transfer(token, beneficiary, Base.getBalance(token));
    }
}

// Copyright (C) 2020 Zerion Inc. <https://zerion.io>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.12;

/**
 * @title Abstract contract storing Wrapped Ether address for the current chain
 */
abstract contract Weth {
    address private immutable weth_;

    /**
     * @notice Sets Wrapped Ether address for the current chain
     * @param weth Wrapped Ether address
     */
    constructor(address weth) {
        weth_ = weth;
    }

    /**
     * @notice Returns Wrapped Ether address for the current chain
     * @return weth Wrapped Ether address
     */
    function getWeth() public view returns (address weth) {
        return weth_;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

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

// Copyright (C) 2020 Zerion Inc. <https://zerion.io>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.12;

import { ActionType, AmountType, PermitType, SwapType } from "./Enums.sol";

//=============================== Adapters Managers Structs ====================================

// The struct consists of adapter name and address
struct AdapterNameAndAddress {
    bytes32 name;
    address adapter;
}

// The struct consists of token and its adapter name
struct TokenAndAdapterName {
    address token;
    bytes32 name;
}

// The struct consists of hash (hash of token's bytecode or address) and its adapter name
struct HashAndAdapterName {
    bytes32 hash;
    bytes32 name;
}

// The struct consists of TokenBalanceMeta structs for
// (base) token and its underlying tokens (if any)
struct FullTokenBalance {
    TokenBalanceMeta base;
    TokenBalanceMeta[] underlying;
}

// The struct consists of TokenBalance struct with token address and absolute amount
// and ERC20Metadata struct with ERC20-style metadata
// 0xEeee...EEeE address is used for Ether
struct TokenBalanceMeta {
    TokenBalance tokenBalance;
    ERC20Metadata erc20metadata;
}

// The struct consists of ERC20-style token metadata
struct ERC20Metadata {
    string name;
    string symbol;
    uint8 decimals;
}

// The struct consists of protocol adapter's name and array of TokenBalance structs
// with token addresses and absolute amounts
struct AdapterBalance {
    bytes32 name;
    TokenBalance[] tokenBalances;
}

// The struct consists of protocol adapter's name and array of supported tokens' addresses
struct AdapterTokens {
    bytes32 name;
    address[] tokens;
}

// The struct consists of token address and its absolute amount (may be negative)
// 0xEeee...EEeE is used for Ether
struct TokenBalance {
    address token;
    int256 amount;
}

//=============================== Interactive Adapters Structs ====================================

// The struct consists of swap type, fee descriptions (share & beneficiary), account address,
// and Caller contract address with call data used for the call
struct SwapDescription {
    SwapType swapType;
    Fee protocolFee;
    Fee marketplaceFee;
    address account;
    address caller;
    bytes callerCallData;
}

// The struct consists of name of the protocol adapter, action type,
// array of token amounts, and some additional data (depends on the protocol)
struct Action {
    bytes32 protocolAdapterName;
    ActionType actionType;
    TokenAmount[] tokenAmounts;
    bytes data;
}

// The struct consists of token address, its amount, and amount type,
// as well as permit type and calldata.
struct Input {
    TokenAmount tokenAmount;
    Permit permit;
}

// The struct consists of permit type and call data
struct Permit {
    PermitType permitType;
    bytes permitCallData;
}

// The struct consists of token address, its amount, and amount type
// 0xEeee...EEeE is used for Ether
struct TokenAmount {
    address token;
    uint256 amount;
    AmountType amountType;
}

// The struct consists of fee share and beneficiary address
struct Fee {
    uint256 share;
    address beneficiary;
}

// The struct consists of deadline and signature
struct ProtocolFeeSignature {
    uint256 deadline;
    bytes signature;
}

// The struct consists of salt and signature
struct AccountSignature {
    uint256 salt;
    bytes signature;
}

// The struct consists of token address and its absolute amount
// 0xEeee...EEeE is used for Ether
struct AbsoluteTokenAmount {
    address token;
    uint256 absoluteAmount;
}

// Copyright (C) 2020 Zerion Inc. <https://zerion.io>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.12;

interface ITokensHandler {
    /**
     * @notice Returns tokens mistakenly sent to this contract
     * @param token Address of token
     * @param beneficiary Address that will receive tokens
     * @dev Can be called only by the owner
     */
    function returnLostTokens(address token, address payable beneficiary) external;
}

// Copyright (C) 2020 Zerion Inc. <https://zerion.io>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.12;

/**
 * @title Abstract contract with basic Ownable functionality and two-step ownership transfer
 */
abstract contract Ownable {
    address private pendingOwner_;
    address private owner_;

    /**
     * @notice Emits old and new pending owners
     * @param oldPendingOwner Old pending owner
     * @param newPendingOwner New pending owner
     */
    event PendingOwnerSet(address indexed oldPendingOwner, address indexed newPendingOwner);

    /**
     * @notice Emits old and new owners
     * @param oldOwner Old contract's owner
     * @param newOwner New contract's owner
     */
    event OwnerSet(address indexed oldOwner, address indexed newOwner);

    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner_, "O: only pending owner");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner_, "O: only owner");
        _;
    }

    /**
     * @notice Initializes owner variable with msg.sender address
     */
    constructor() {
        emit OwnerSet(address(0), msg.sender);

        owner_ = msg.sender;
    }

    /**
     * @notice Sets pending owner to the `newPendingOwner` address
     * @param newPendingOwner Address of new pending owner
     * @dev The function is callable only by the owner
     */
    function setPendingOwner(address newPendingOwner) external onlyOwner {
        emit PendingOwnerSet(pendingOwner_, newPendingOwner);

        pendingOwner_ = newPendingOwner;
    }

    /**
     * @notice Sets owner to the pending owner
     * @dev The function is callable only by the pending owner
     */
    function setOwner() external onlyPendingOwner {
        emit OwnerSet(owner_, msg.sender);

        owner_ = msg.sender;
        delete pendingOwner_;
    }

    /**
     * @return owner Owner of the contract
     */
    function getOwner() external view returns (address owner) {
        return owner_;
    }

    /**
     * @return pendingOwner Pending owner of the contract
     */
    function getPendingOwner() external view returns (address pendingOwner) {
        return pendingOwner_;
    }
}