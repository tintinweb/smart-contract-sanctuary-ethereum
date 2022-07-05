/**
 *Submitted for verification at Etherscan.io on 2022-07-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Test {

    uint public x = 10;
    address payable public owner = payable(msg.sender);

    receive() external payable {
    }

    function destroy() external {
        selfdestruct(payable(msg.sender));
    }
    
}