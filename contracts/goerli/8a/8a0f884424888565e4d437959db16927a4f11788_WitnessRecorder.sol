/**
 *Submitted for verification at Etherscan.io on 2023-01-06
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract WitnessRecorder {
    mapping(address => bool) public isRegistered;
    mapping(address => uint256) public nextNonce;
    mapping(address => uint256) public lastTimestamp;
    mapping(address => mapping(uint256 => bytes)) public HashOfNonce;
    mapping(address => mapping(uint256 => uint256)) public TimestampOfNonce;

    modifier onlyRegistered() {
        require(isRegistered[msg.sender], "not registered");
        _;
    }

    function getIsRegistered(address recorder) public view returns (bool) {
        return isRegistered[recorder];
    }

    function getNextNonce(address recorder) public view returns (uint256) {
        return nextNonce[recorder];
    }

    function getlastTimestamp(address recorder) public view returns (uint256) {
        return lastTimestamp[recorder];
    }

    function getHashOfNonce(address recorder, uint256 nonce)
        public
        view
        returns (bytes memory)
    {
        return HashOfNonce[recorder][nonce];
    }

    function getTimestampOfNonce(address recorder, uint256 nonce)
        public
        view
        returns (uint256)
    {
        return TimestampOfNonce[recorder][nonce];
    }

    function register() public {
        require(!isRegistered[msg.sender]);
        isRegistered[msg.sender] = true;
    }

    function addRecord(bytes calldata recordHash) public onlyRegistered {
        uint256 nowTime = block.timestamp;
        uint256 nonce = nextNonce[msg.sender];
        nextNonce[msg.sender] = nonce + 1;
        lastTimestamp[msg.sender] = nowTime;
        HashOfNonce[msg.sender][nonce] = recordHash;
        TimestampOfNonce[msg.sender][nonce] = nowTime;
    }
}