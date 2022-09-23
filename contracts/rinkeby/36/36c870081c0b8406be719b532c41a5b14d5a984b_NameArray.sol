/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0
// 20220923
pragma solidity 0.8.0;

contract NameArray {

    string[] nameArray;
    
    function pushName(string memory name) public {
        nameArray.push(name);
    }

    function getName(uint _n) public view returns(string memory) {
        return nameArray[_n-1];
    }

}