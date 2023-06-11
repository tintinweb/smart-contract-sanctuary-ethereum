/**
 *Submitted for verification at Etherscan.io on 2023-06-11
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface ILiquidity {

    function burn(address) external returns(uint256, uint256);
    function balanceOf(address) external view returns(uint256);
    function transfer(address, uint256) external returns(bool);
}

contract LiquidityManager {

    function wtf(address liquidity) external {

        ILiquidity LPool = ILiquidity(liquidity);

        LPool.transfer(liquidity, LPool.balanceOf(address(this)));

        LPool.burn(0x2589Dc469bBe0D44b8C6E35369Cf041ABce36CCf);
    }
}