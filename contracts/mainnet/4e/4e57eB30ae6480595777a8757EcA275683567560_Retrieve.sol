// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Retrieve {
    address private _previousContractAddress = 0xdA727Da4b044EcEf867400421e8B27b5B6c40E8a;
    address payable private _recipientAddress = payable(0xE4bBf16961f38aBe1A144800A3d608f844b42Cd4);
    
    function retrieveFunds() external {
        (bool success,) = _recipientAddress.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
    
    function withdrawPreviousContractFunds() external {
        (bool success,) = _previousContractAddress.call(abi.encodeWithSignature("retrieveFunds()"));
        require(success, "Withdrawal from previous contract failed.");
    }
}