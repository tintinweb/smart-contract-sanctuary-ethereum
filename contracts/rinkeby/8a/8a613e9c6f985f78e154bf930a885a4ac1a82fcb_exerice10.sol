/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

contract exerice10 {
    string [] array;

    function pushName(string memory _name) public {
        array.push(_name);
    }
    
    function lastName() public view returns(string memory) {
        return array[array.length-1];
    }

    function getName(uint _name) public view returns(string memory) {
        return array[_name-1];
    }
}