// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract INFO {
    string[] private info;
    
    function put(string calldata _info) public returns(uint256) {
        info.push(_info);
        return info.length;
    }

    function get(uint256 _index) public view returns(string memory) {
        string memory _info = info[_index-1];
        return _info;
    }
}