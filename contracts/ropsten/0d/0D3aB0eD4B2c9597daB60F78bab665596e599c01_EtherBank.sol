/**
 *Submitted for verification at Etherscan.io on 2022-03-10
*/

// SPDX-License-Identifier: MIT
pragma solidity >0.7.0 <0.9.0;
contract EtherBank{
    mapping(address=>uint) party;
    function collect() external payable{
        party[msg.sender]+=msg.value;
    }

    function trasferTo(address payable to,uint amount) external{
        (bool sent,)=to.call{value:amount}(""); //send equvalent ether to target user
        require(sent,"revert, no fallback or receive at callee");
    }
}