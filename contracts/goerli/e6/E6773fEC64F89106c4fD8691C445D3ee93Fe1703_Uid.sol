/**
 *Submitted for verification at Etherscan.io on 2023-03-19
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";
// import {Crypto} from "@openzeppelin/contracts/utils/cryptography/Crypto.sol";


contract Uid {
    mapping (address => uint256) private balances;
    mapping (address => uint256) private attempts;
    uint256 private constant fee = 1000000000000000; // in wei

    event Verify__event(address indexed sender);

    function adh_pin(uint256 adhaarNum,  uint256 pin) public pure returns (bytes32) {
        uint256 num = adhaarNum+ pin;
        bytes32 hash = sha256(abi.encodePacked(num));
        return hash;
    }
    
    function demography( string memory name, string memory city, string memory date) public pure returns (bytes32) {
        string memory str = string(abi.encodePacked(name, city, date));
        //  bytes32 hash = Crypto.hash(bytes(str));
        bytes32 hash = sha256(abi.encodePacked(str));
         return hash;
    }

    
    function addBalance() public payable {
        balances[msg.sender] += msg.value;
        attempts[msg.sender]+= msg.value/fee;
    }

    function getBalance(address addr) public view returns (uint256) {
        return balances[addr];
    }

    function getAttempts(address addr) public view returns (uint256) {
        return attempts[addr];
    }

    function verify() public {
        require(attempts[msg.sender]>0);
        attempts[msg.sender]--;
        balances[msg.sender]-=1000000000000000;
        emit Verify__event(msg.sender);
    }
}