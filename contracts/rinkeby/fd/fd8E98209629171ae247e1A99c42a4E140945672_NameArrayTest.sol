/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

contract NameArrayTest {
    string[] nameArray;
    
    function push(string memory name) public {
        nameArray.push(name);
    }

    function get(uint idx) public view returns(string memory) {
        return nameArray[idx - 1];
    }

    function lastest() public view returns(string memory) {
        return nameArray[nameArray.length - 1];
    }

    function length() public view returns(uint) {
        return nameArray.length;
    }

    function pop() public {
        nameArray.pop();
    }
}