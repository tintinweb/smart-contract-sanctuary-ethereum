/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

contract Name {
    
    string[] stringArray;

    function pushString(string memory s) public {
        stringArray.push(s);
    }

    function getStringArrayLength() public view returns(uint) {
        return stringArray.length;
    }

    function getString(uint _n) public view returns(string memory) {
        return stringArray[_n - 1];
    }

}