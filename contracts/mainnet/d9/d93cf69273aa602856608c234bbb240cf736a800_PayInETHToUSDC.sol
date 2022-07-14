/**
 *Submitted for verification at Etherscan.io on 2022-07-13
*/

//SPDX-License-Identifier: MIT
/****
 ***** this code and any deployments of this code are strictly provided as-is;
 ***** no guarantee, representation or warranty is being made, express or implied, as to the safety or correctness of the code
 ***** or any smart contracts or other software deployed from these files,
 ***** in accordance with the disclosures and licenses found here: https://github.com/V4R14/firm_utils/blob/main/LICENSE
 ***** this code is not audited, and users, developers, or adapters of these files should proceed with caution and use at their own risk.
 *****
 ****/

pragma solidity >=0.8.4;

/// @title Pay In ETH To USDC
/// @dev uses Uniswap router to swap incoming ETH for USDC tokens, then sends to receiver address (initially, the deployer)
/// @notice permits payment for services denominated in ETH but receiving USDC

interface IUniswapV2Router02 {
    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);
}

contract PayInETHToUSDC {
    address constant UNI_ROUTER_ADDR =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address constant USDC_ADDR = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant WETH_ADDR = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public receiver;

    IUniswapV2Router02 immutable uniRouter;

    error CallerNotCurrentReceiver();

    constructor() payable {
        uniRouter = IUniswapV2Router02(UNI_ROUTER_ADDR);
        receiver = msg.sender;
    }

    /// @notice receives ETH payment and swaps to USDC via UniswapV2 router, which is then sent to receiver
    receive() external payable {
        uniRouter.swapExactETHForTokens{value: msg.value}(
            0,
            _getPathForETHtoUSDC(),
            receiver,
            block.timestamp
        );
    }

    /// @notice allows current receiver address to change the receiver address for payments
    /// @param _newReceiver: new address to receive USDC tokens
    function changeReceiver(address _newReceiver) external {
        if (msg.sender != receiver) revert CallerNotCurrentReceiver();
        receiver = _newReceiver;
    }

    /// @return path: the router path for ETH/USDC swap
    function _getPathForETHtoUSDC() internal pure returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = WETH_ADDR;
        path[1] = USDC_ADDR;
        return path;
    }
}