// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract MyContract {
    string public name;

    function changename(string memory _name)public returns(string memory){
        name = _name;
        return name;
    }
}