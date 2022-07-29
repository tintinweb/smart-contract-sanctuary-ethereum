/**
 *Submitted for verification at Etherscan.io on 2022-07-29
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

//"0xc721bf7a3539abdf8040b10c0908f33f88f97a79" buyback
// 0xc778417e063141139fce010982780140aa0cd5ab weth

contract SeaGoldTrade {
    function saleToken(address payable buyback, uint256 amount) public payable {
        buyback.transfer(amount);
    }

    function AcceptBId(
        address ethAddr,
        uint256 amount,
        address payable buyback
    ) public {
        IWETH convertToken = IWETH(ethAddr);
        convertToken.withdraw(amount);
        buyback.transfer(amount);
    }
}