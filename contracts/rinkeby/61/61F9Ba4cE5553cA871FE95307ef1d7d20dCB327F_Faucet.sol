/**
 *Submitted for verification at Etherscan.io on 2022-05-20
*/

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Faucet {
    // Keep track of the block number when each account last executed a withdraw.
    mapping(address => uint256) lastWithdraw;

    function withdraw (uint _amount) public {
        // Users can only withdraw 0.01 ETH at a time, and it cannot be
        // within 100 blocks of their last successful withdrawl.
        require(_amount <= 10000000000000000);
        require(block.number - lastWithdraw[msg.sender] >= 100);
        lastWithdraw[msg.sender] = block.number;
        payable(msg.sender).transfer(_amount);
    }

    // fallback function
    receive () external payable {}
}