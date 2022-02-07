/**
 *Submitted for verification at Etherscan.io on 2022-02-07
*/

///SPDX-License-Identifier: MIT

pragma solidity >0.6.0;

contract HelloWorld{
    string name;
    function nameSet(string memory  nm) public {
        name = nm;
    }
    function getInfo() public view returns(string memory nm) {
        return name;
    }
}