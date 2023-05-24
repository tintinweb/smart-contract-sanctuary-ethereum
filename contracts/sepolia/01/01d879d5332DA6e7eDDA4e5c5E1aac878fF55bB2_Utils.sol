// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

// import "hardhat/console.sol";

library Utils {
    function getBalance(address addr) external view returns (uint) {
        return addr.balance;
    }

    function generateTransactionHash(
        address sender,
        uint256 nonce
    ) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(sender, nonce));
    }
}