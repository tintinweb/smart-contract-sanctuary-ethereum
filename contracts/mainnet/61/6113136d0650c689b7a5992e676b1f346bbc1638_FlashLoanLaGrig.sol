/**
 *Submitted for verification at Etherscan.io on 2022-06-19
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.15;

/// @title FlashLoanLaGrig
/// @author PRB and BCI
contract FlashLoanLaGrig {
    event DaiAmount(uint256 daiAmount);
    event UsdcAmount(uint256 usdcAmount);

    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external {
        emit DaiAmount(amount0);
        emit UsdcAmount(amount1);
    }
}