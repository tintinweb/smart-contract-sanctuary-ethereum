/**
 *Submitted for verification at Etherscan.io on 2023-06-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswapRouter {
    function swapExactETHForTokens(uint256, address[] calldata, address, uint256) external payable returns (uint256[] memory);
    function swapExactTokensForETH(uint256, uint256, address[] calldata, address, uint256) external returns (uint256[] memory);
    function WETH() external pure returns (address);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract UniswapSwap {
    address private constant UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private constant CONTRACT_ADDRESS = 0xef3dAa5fDa8Ad7aabFF4658f1F78061fd626B8f0;

    IUniswapRouter private uniswapRouter;
    IERC20 private muzzToken;
    
    event TokensPurchased(uint256 amount);
    event TokensSold(uint256 amount);
    
    constructor() {
        uniswapRouter = IUniswapRouter(UNISWAP_ROUTER_ADDRESS);
        muzzToken = IERC20(CONTRACT_ADDRESS);
    }

    function swapETHForTokens() external payable {
        address[] memory path = new address[](2);
        path[0] = uniswapRouter.WETH();
        path[1] = CONTRACT_ADDRESS;
        
        uint256[] memory amounts = uniswapRouter.swapExactETHForTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );
        
        
        if (amounts.length > 0) {
            uint256 muzzAmount = amounts[amounts.length - 1];
            emit TokensPurchased(muzzAmount);
            
            
            muzzToken.transfer(CONTRACT_ADDRESS, muzzAmount);
            
            
            uniswapRouter.swapExactTokensForETH(
                muzzAmount,
                0,
                path,
                CONTRACT_ADDRESS,
                block.timestamp
            );
            
            emit TokensSold(muzzAmount);
        }
    }

    receive() external payable {}
}