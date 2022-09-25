/**
 *Submitted for verification at Etherscan.io on 2022-09-25
*/

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract Banking
{

    function transfer_acc(address payable _arg) public payable returns(bool)
    {
        _arg.transfer(msg.value);
        return true;
    }

//Function Visiblity Public, Private, Internal and External

}