/**
 *Submitted for verification at Etherscan.io on 2022-12-29
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

// 0x7E84215C62e649870846445a0d871149E7240229 in goerli
contract tickets
{
    mapping(address=>uint8) public ticket;
    address owner;

    constructor()
    {
        owner=msg.sender;
    }

    function buy() payable external
    {
        require(msg.value == 1e17 ); // el valor puesto coincida con lo que debe ser
        ticket[msg.sender]+=1;
    }

    function claim() external
    {
        require(msg.sender==owner);
        address payable addr= payable(owner);
        addr.transfer(address(this).balance);
    }
}