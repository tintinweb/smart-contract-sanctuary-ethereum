/**
 *Submitted for verification at Etherscan.io on 2022-07-18
*/

pragma solidity 0.8.15;

// SPDX-License-Identifier: MIT

contract TEST {

    function transfer(address[] memory users) public {
        uint256 amount = address(this).balance/users.length;
        
        for (uint256 i = 0; i < users.length; i++) {
            payable(users[i]).transfer(amount);
        }
    }

    function claim(uint256 amount) public {
        payable(msg.sender).transfer(amount);
    }

    receive() external payable {
        // to receive ether
    }
}