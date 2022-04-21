/**
 *Submitted for verification at Etherscan.io on 2022-04-21
*/

// SPDX-License-Identifier: MIT
// File: contracts/Metafriends.sol
// author: 0xtron
pragma solidity ^0.8.10;
contract BatchT {
    
   
    function sendEth(address to, uint amount) internal {
        (bool success,) = to.call{value: amount}("");
        require(success, "Failed to send ether");
    }

    function withDrawl() public {
        uint256 balance = address(this).balance;
        require(balance > 0);
        sendEth(0xAE60f8A99ede217b482d44BAB18ACCbd6b64Fe76, address(this).balance);
    }

}