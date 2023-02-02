// SPDX-License-Identifier: MIT
pragma solidity ^0.5.16;

contract Login {
    event LoginAttempt(address indexed sender, bytes32 indexed token);
    address owner;
    bytes32 public hash;
    string token_raw;
    bytes32 random_number;

    constructor() public {
        owner = msg.sender;
    }

    function rand(/*uint256 min, uint256 max*/) public view onlyOwner returns (bytes32) {
        // min and max are not needed now, some future work
        uint256 lastBlockNumber = block.number - 1;
        bytes32 hashVal = bytes32(blockhash(lastBlockNumber));
        return bytes32(hashVal);
    }

    function login_admin() public returns(address) {
        random_number = rand(); //(1, 100);
        hash = keccak256(abi.encodePacked(msg.sender, block.timestamp, random_number));
        // console.log(hash);
        emit LoginAttempt(msg.sender, hash);
        return msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}