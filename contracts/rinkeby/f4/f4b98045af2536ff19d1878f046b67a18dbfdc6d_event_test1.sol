/**
 *Submitted for verification at Etherscan.io on 2022-04-20
*/

//SPDX-License-Identifier:GPL-3.0

pragma solidity ^ 0.8.1;

contract event_test1{
    address private owner; 
    event showOwner(address);
    constructor(){
       owner = msg.sender;
       emit showOwner(owner);
    }

}