/**
 *Submitted for verification at Etherscan.io on 2022-03-28
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IWETH9 {
    function balanceOf(address) external returns (uint);
    function deposit() external payable;
    function withdraw(uint wad) external;
    function transfer(address dst, uint wad) external returns (bool);
    function transferFrom(address src, address dst, uint wad) external returns (bool);
}

contract Withdraw {
    IWETH9 weth9;

    constructor(address weth9_addr) {
        weth9 = IWETH9(weth9_addr);
    }

    receive() external payable {
    }

    function withdraw(uint256 amount, address payable to) external returns (bool) {
        weth9.transferFrom(msg.sender, address(this), amount);
        weth9.withdraw(amount);
        return to.send(amount);
    }
}