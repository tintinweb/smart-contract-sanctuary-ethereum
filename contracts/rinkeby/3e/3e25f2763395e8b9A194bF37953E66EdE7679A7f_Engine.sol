// SPDX-License-Identifier: unlicenced
pragma solidity ^0.8.0;
import "./ISwapRouter.sol";

interface IUniSwapRouter is ISwapRouter {
    function refundETH() external payable;
}

contract Engine {
    IUniSwapRouter uniswap;
    address private constant multiDaiKovan = 0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa;
    address private constant WETH9 = 0xd0A1E359811322d97991E03f863a0C30C2cF029C;
    address private constant UniswapAddress = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

    receive() payable external {}

    function convertETHToDAI() external payable {
        revert("POF");
        require(msg.value > 0, "You must send ETH");
        uint256 deadline = block.timestamp + 15; // using 'now' for convenience, for mainnet pass deadline from frontend!
        address tokenIn = WETH9;
        address tokenOut = multiDaiKovan;
        uint24 fee = 3000;
        address recipient = msg.sender;
        uint256 amountIn = msg.value;
        uint256 amountOutMinimum = 1;
        uint160 sqrtPriceLimitX96 = 0;

        ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter.ExactOutputSingleParams(tokenIn,
        tokenOut,
        fee,
        recipient,
        deadline,
        amountIn,
        amountOutMinimum,
        sqrtPriceLimitX96);
        uniswap = IUniSwapRouter(UniswapAddress);

        uniswap.exactOutputSingle{value: msg.value}(params);
        uniswap.refundETH();

        (bool success, ) = msg.sender.call{value: address(this).balance }("");
        require(success, "Refund to caller failed");
    }

}

// SPDX-License-Identifier: unlicenced
pragma solidity ^0.8.0;

interface ISwapRouter {
    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);
}