/**
 *Submitted for verification at Etherscan.io on 2022-02-23
*/

//SPDX-License-Identifier: MIT
/**** 
***** this code and any deployments of this code are strictly provided as-is; no guarantee, representation or warranty is being made, express or implied, as to the safety or correctness of the code 
***** or any smart contracts or other software deployed from these files. This code has not been audited and as such there can be no assurance they will work as intended, and 
***** users may experience delays, failures, errors, omissions or loss of transmitted information. Any users, developers, or adapters of these files should proceed with caution and use at their own risk.
***** Do not use absent written direction by Varia LLC - any funds, tokens, or other digital assets sent to this contract may be permanently lost.
****/

pragma solidity ^0.8.0;

/// @title Pay Varia ETH
/// @notice uses Sushiswap router to swap incoming ETH for USDC tokens, then sends to varia.eth

interface IUniswapV2Router02 {
    function swapExactETHForTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external payable returns (uint256[] memory amounts);
    function WETH() external pure returns (address);
}

interface IUSDC  { 
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract PayVariaETH {

    address constant USDC_TOKEN_ADDR = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // USDC mainnet token contract address
    address constant SUSHI_ROUTER_ADDR = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F; // Sushiswap router contract address
    address constant VARIA_ADDR = 0xD4B2747e87e7bE8CA0d68A249b90738b5aB2E85a; // varia.eth EOA address

    IUniswapV2Router02 public sushiRouter;
    IUSDC public iUSDCToken;

    error NoETHSent();
    error NoUSDC();

    constructor() payable {
        sushiRouter = IUniswapV2Router02(SUSHI_ROUTER_ADDR);
        iUSDCToken = IUSDC(USDC_TOKEN_ADDR);
    }

    /// @notice receives ETH payment and swaps to USDC via Sushiswap router, which is then sent to varia.eth. Intended only as a payment option for clients of Varia LLC.
    function payInETH() public payable {
        if (msg.value == 0) revert NoETHSent();
        sushiRouter.swapExactETHForTokens{ value: msg.value }(0, _getPathForETHtoUSDC(), address(this), block.timestamp+100);
        _sendUSDC();
    }

    function _sendUSDC() internal {
        if (iUSDCToken.balanceOf(address(this)) == 0) revert NoUSDC();
        iUSDCToken.transfer(VARIA_ADDR, iUSDCToken.balanceOf(address(this)));
    }
    
    /// @return the router path for ETH/USDC swap for the payInETH() function
    function _getPathForETHtoUSDC() internal view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = sushiRouter.WETH(); //0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2
        path[1] = USDC_TOKEN_ADDR;
        return path;
    }

    receive() payable external {}
}