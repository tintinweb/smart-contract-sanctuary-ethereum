/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

contract aaab {
    string[] names;

    function pushName(string memory _str) public {
        names.push(_str);
    }

    function getName(uint index) public view returns(string memory) {
        return names[index-1];
    }

    function getNamesLength() public view returns(uint) {
        return names.length;
    }

}