/**
 *Submitted for verification at Etherscan.io on 2022-02-07
*/

pragma solidity ^0.8.0;

contract hashGenerator {
    function generateHash(address contractAddress, bytes32 nonce, address messageSender, uint256 saleType, uint256 amount) external pure returns (bytes32) {
        bytes32 hash = keccak256(abi.encodePacked(contractAddress, messageSender, amount, nonce, saleType));
        return hash;
    }
    }