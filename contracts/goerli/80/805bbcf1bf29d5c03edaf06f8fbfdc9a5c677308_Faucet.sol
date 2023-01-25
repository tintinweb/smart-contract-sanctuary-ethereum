/**
 *Submitted for verification at Etherscan.io on 2023-01-25
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract Faucet {

    function withdraw(uint _amount) public {
    // users can only withdraw .1 ETH at a time, feel free to change this!
    require(_amount <= 100000000000000000);
    payable(msg.sender).transfer(_amount);
    }

    function standardWithdraw() public {
        // users can only withdraw .1 ETH at a time, feel free to change this!
        payable(msg.sender).transfer(10000000000000000);
    }

    // fallback function
    receive() external payable {}
}