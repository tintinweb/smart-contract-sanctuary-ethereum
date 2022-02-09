/**
 *Submitted for verification at Etherscan.io on 2022-02-09
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Register {
    string private info;

    function setInfo(string memory _info) public {
        info = _info;
    }
    
    function getInfo() public view returns (string memory) {
        return info;
    }
}