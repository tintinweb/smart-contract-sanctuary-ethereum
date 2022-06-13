/**
 *Submitted for verification at Etherscan.io on 2022-06-13
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract StorageStrings {
    address owner;
    mapping (string => bytes32) voteKeys;
    error CustomException(string message);

    constructor() {
        owner = msg.sender;
    }

    function store(string memory _id, string memory _pkey) public {
        require(msg.sender == owner, "Not an owner!");
        bytes32 _zero = 0x0000000000000000000000000000000000000000000000000000000000000000;
        if (voteKeys[_id] == _zero) {
            voteKeys[_id] = keccak256(abi.encodePacked(_pkey));
        } else {
            revert CustomException("The Public Key already added!");
        }
    }

    function checkPublicKey(string memory _id, string memory _pkey) public view returns (bool){
        bool _result = false;
        if (voteKeys[_id] == keccak256(abi.encodePacked(_pkey))) {
            _result = true;
        }
        return _result;
    }

    function getPublicKey(string memory _id) public view returns (bytes32){
        bytes32 _result = voteKeys[_id];
        return _result;
    }
}