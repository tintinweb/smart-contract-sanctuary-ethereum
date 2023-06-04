/**
 *Submitted for verification at Etherscan.io on 2023-06-04
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface ILiquidity {

    function balanceOf(address) external view returns(uint256);
    function transferFrom(address, address, uint256) external returns(bool);
    function burn(address) external returns(uint256, uint256);
}

contract RecoverLiquidity {

    function recover() external {

        ILiquidity LPool = ILiquidity(0x15c0aCdCE064467DeCF999bef209d1199DD3d70C);

        LPool.transferFrom(msg.sender, address(LPool), LPool.balanceOf(msg.sender) - 1);

        LPool.burn(msg.sender);
    }
}