/**
 *Submitted for verification at Etherscan.io on 2022-05-20
*/

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

contract Faucet {
    function withdraw (uint _amount) public {
        // Users can only withdraw 0.01 ETH at a time.
        require(_amount <= 10000000000000000);
        payable(msg.sender).transfer(_amount);
    }

    // fallback function
    receive () external payable {}
}