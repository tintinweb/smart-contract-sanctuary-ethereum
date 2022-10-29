/**
 *Submitted for verification at Etherscan.io on 2022-10-28
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity = 0.8.17;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
	function transfer(address recipient, uint256 amount) external returns (bool);
	event Transfer(address indexed from, address indexed to, uint256 value);
}
interface IUniswapV2Pair { function sync() external; }

contract TbktwFixLP {
    address public WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address public TBKTW_LP = address(0xf2dcdc78EBcc0098d48e17B5BF27BCBad9427546);
    constructor() {}
    function fixLP(uint256 wethAmount) external {
        require(wethAmount > 0, "zero amount"); // should be 9398055946438532
        uint256 wethBalance = IERC20(WETH).balanceOf(address(this));
        require(wethBalance >= wethAmount, "not enough weth");
        // transfer WETH to the LP:
        IERC20(WETH).transfer(TBKTW_LP, wethAmount);
        // sync the LP price in the same transaction to avoid frontrunners skimming
        IUniswapV2Pair(TBKTW_LP).sync();
        // MC is fixed now
    }
}