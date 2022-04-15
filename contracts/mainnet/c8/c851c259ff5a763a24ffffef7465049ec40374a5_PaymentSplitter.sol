/**
 *Submitted for verification at Etherscan.io on 2022-04-15
*/

// File: PaymentSplitter.sol


pragma solidity ^0.8.0;

contract PaymentSplitter {
    receive() external payable {
        address[2] memory addresses = [
            0xA99308B317259B7627DE0AB553E54A7E1702bb03,
            0x00889fc62F0b701e6393A99495F9d0b24C8858E8
        ];

        uint32[2] memory shares = [
            uint32(8800),
            uint32(1200)
        ];

        uint256 balance = address(this).balance;

        for (uint32 i = 0; i < addresses.length; i++) {
            uint256 amount = i == addresses.length - 1
                ? address(this).balance
                : (balance * shares[i]) / 10000;

            (bool success, ) = addresses[i].call{value: amount}("");
            require(success, "Failed to send payment");
        }
    }
}