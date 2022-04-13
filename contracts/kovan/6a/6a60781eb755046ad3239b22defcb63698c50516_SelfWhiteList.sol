/**
 *Submitted for verification at Etherscan.io on 2022-04-13
*/

// SPDX-License-Identifier: MIT
pragma solidity^0.8.0;
contract SelfWhiteList{
    mapping(address=>bool)users;
    function whitelist() public {
        require(!users[msg.sender]);
        users[msg.sender]=true;
    }
    function check() public view returns(bool){
      return users[msg.sender];
    }
}