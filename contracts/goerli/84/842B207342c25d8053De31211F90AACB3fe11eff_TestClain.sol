/**
 *Submitted for verification at Etherscan.io on 2023-02-24
*/

/**
 *Submitted for verification at BscScan.com on 2022-04-01
*/
pragma solidity 0.8.11;

// SPDX-License-Identifier: MIT

contract TestClain {

    address public owner;
    address public conAddress;

    event log(address addr);

    constructor()  {
        owner = msg.sender;
        conAddress = address(this);
        emit log(msg.sender);
        emit log(address(this));
    }

    function claim() external{
        payable(conAddress).transfer(0.01 ether);
    }
}