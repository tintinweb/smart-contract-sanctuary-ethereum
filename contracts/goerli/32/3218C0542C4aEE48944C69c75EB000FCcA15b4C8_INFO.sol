// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract INFO {
    string[] private info;

    event PutInfo(address indexed sender, uint256 infoId);
    
    function put(string calldata _info) public returns(uint256 _infoId) {
        info.push(_info);
        _infoId = info.length;
        emit PutInfo(msg.sender, _infoId);
    }

    function get(uint256 _index) public view returns(string memory _info) {
        _info = info[_index-1];
    }
}