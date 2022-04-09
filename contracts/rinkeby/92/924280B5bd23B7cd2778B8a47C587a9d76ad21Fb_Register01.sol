/**
 *Submitted for verification at Etherscan.io on 2022-04-08
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
 
contract Register01 {
    string private info;
   
    function getInfo() public view returns (string memory) {
        return info;
    }
 
    function setInfo(string memory _info) public {
        info = _info;
    }
}