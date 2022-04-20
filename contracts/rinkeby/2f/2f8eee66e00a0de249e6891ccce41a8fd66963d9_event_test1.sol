/**
 *Submitted for verification at Etherscan.io on 2022-04-20
*/

//SPDX-License-Identifier:GPL-3.0

pragma solidity ^ 0.8.1;

contract event_test1{
    address private owner; 
    event showOwner(address);
    event showResult1(string);
    event showResult2(string);
    event showResult3(string);

    constructor(){
       owner = msg.sender;
       emit showOwner(owner);
    }

    function f1(string memory msg1)  public{
        string memory result = string(abi.encodePacked("Weather is ",msg1));
        emit showResult1(result);
        
    }

}