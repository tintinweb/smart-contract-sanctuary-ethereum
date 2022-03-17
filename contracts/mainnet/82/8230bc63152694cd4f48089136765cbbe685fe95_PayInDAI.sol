/**
 *Submitted for verification at Etherscan.io on 2022-03-16
*/

//SPDX-License-Identifier: MIT
/**** 
***** this code and any deployments of this code are strictly provided as-is; no guarantee, representation or warranty is being made, express or implied, as to the safety or correctness of the code 
***** or any smart contracts or other software deployed from these files, in accordance with the disclosures and licenses found here: https://github.com/ErichDylus/Open-Source-Law/tree/main/solidity#readme
***** this code is not audited, and users, developers, or adapters of these files should proceed with caution and use at their own risk.
***** deployed by varia.eth at 0x3A3bBa660CFE4AB05fcC52829245583b913c740C
****/

pragma solidity >=0.8.0;

/// @title Pay In DAI
/// @dev uses Sushiswap router to swap incoming DAI for USDC tokens, then sends to deployer address
/// @notice permits payment for services denominated in DAI but receiving USDC, avoiding additional unnecessary de minimus taxable event by deployer to cash out USDC

interface IUniswapV2Router02 {
    function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external payable returns (uint256[] memory amounts);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

contract PayInDAI {
    
    address constant DAI_TOKEN_ADDR = 0x6B175474E89094C44Da98b954EedeAC495271d0F; // DAI mainnet token contract address
    address constant USDC_TOKEN_ADDR = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // USDC mainnet token contract address
    address constant SUSHI_ROUTER_ADDR = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F; // Sushiswap router contract address
    address receiver; 

    IUniswapV2Router02 public sushiRouter;
    IERC20 public ierc20;

    error CallerNotCurrentReceiver();

    constructor() payable {
        sushiRouter = IUniswapV2Router02(SUSHI_ROUTER_ADDR);
        ierc20 = IERC20(DAI_TOKEN_ADDR);
        receiver = msg.sender;
    }

    /// @notice receives DAI payment and swaps to USDC via Sushiswap router, which is then sent to receiver.
    /// @dev sender must approve address(this) for amount of DAI
    /// @param amount of DAI tokens
    function payDAI(uint256 amount) external {
        ierc20.transferFrom(msg.sender, address(this), amount);
        sushiRouter.swapExactTokensForTokens(amount, 0, _getPathForDAItoUSDC(), receiver, block.timestamp);
    }

    /// @return the router path for DAI/USDC swap
    function _getPathForDAItoUSDC() internal pure returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = DAI_TOKEN_ADDR;
        path[1] = USDC_TOKEN_ADDR;
        return path;
    }
}