/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0
// 20220923
pragma solidity 0.8.0;


contract choolsuck {

    string[] sarray;

    function pushName(string memory s) public {
        sarray.push(s);
    }
    
    function getSarrayLength() public view returns(uint) {
        return sarray.length;
    }
    
    function getString(uint _n) public view returns(string memory) {
        return sarray[_n-1];
    }

}