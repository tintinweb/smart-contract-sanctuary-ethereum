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
pragma solidity ^0.8.17;

// Simple SwapRouter interface to allow the UniswapSwapAdapter to be compiled in 0.8.17
interface ISwapRouter02 {
    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ISwapRouter02 } from "./ISwapRouter02.sol";

error incorrectOutputToken();

/**
 * @dev this contract exposes necessary logic to swap between tokens using Uniswap.
 * note that it should only hold tokens mid-transaction. Any tokens transferred in outside of a swap can be stolen.
 */
contract UniswapSwapAdapter {
    address public immutable swapRouter;

    constructor(address _swapRouter) {
        swapRouter = _swapRouter;
    }

    // exactInput
    function swap(address _outputToken, bytes calldata _swapData) external returns (uint256) {
        // Decode swap data
        (uint256 deadline, uint256 _amountIn, uint256 _amountOutMinimum, bytes memory _path) = abi.decode(
            _swapData,
            (uint256, uint256, uint256, bytes)
        );

        // Check that the outputToken is the final token in the path
        uint256 length = _swapData.length;
        address swapOutputToken = address(bytes20(_swapData[length - 41:length - 21]));

        if (swapOutputToken != _outputToken) {
            // The keeper-inputted Output Token differs from what the contract says it must be.
            revert incorrectOutputToken();
        }

        // Perform swap (this will fail if tokens haven't been transferred in, or haven't been approved)
        ISwapRouter02.ExactInputParams memory params = ISwapRouter02.ExactInputParams({
            path: _path,
            recipient: msg.sender,
            deadline: deadline,
            amountIn: _amountIn,
            amountOutMinimum: _amountOutMinimum
        });

        return ISwapRouter02(swapRouter).exactInput(params);
    }

    /**
     * @dev approve any token to the swapRouter.
     * note this is calleable by anyone.
     */
    function approveTokens(address _tokenIn) external {
        IERC20(_tokenIn).approve(swapRouter, type(uint256).max);
    }
}