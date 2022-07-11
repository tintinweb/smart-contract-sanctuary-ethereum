/**
 *Submitted for verification at Etherscan.io on 2022-07-11
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract pigpig {

    uint public goal;
    address payable admin;
    constructor(uint _goal)
    {
        goal = _goal; 
    }
    receive() external payable{}

    function getBalance() public view returns(uint)
    {
        return address(this).balance;
    }

    function withdraw() public
    {
        if(getBalance() > goal)
        {
            selfdestruct(payable(msg.sender));
        }
    }


}