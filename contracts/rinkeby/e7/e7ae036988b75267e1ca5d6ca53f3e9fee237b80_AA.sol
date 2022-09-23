/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

contract AA {
    string[] sarray;

    function pushName(string memory _name) public {
        sarray.push(_name);
    }

    function getString(uint _n) public view returns(string memory, uint){
        return (sarray[_n-1], _n);
    }
}