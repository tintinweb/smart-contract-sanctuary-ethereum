/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

contract practice3 {
    string[] sarray;

    function name(string memory a) public {
        sarray.push(a);
    }
    function getsarrayLength() public view returns(uint) {
        return sarray.length;
    }
    function nsarray(uint _n) public view returns(string memory) {
        return sarray[_n-1];    
    }
}