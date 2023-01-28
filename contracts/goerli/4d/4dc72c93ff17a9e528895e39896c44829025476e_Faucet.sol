/**
 *Submitted for verification at Etherscan.io on 2023-01-28
*/

//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.17;

contract Faucet {
    function withdraw(uint256 _amount) public {
        // limit withdraw amount to 0.1 ether
        require(
            _amount <= 100000000000000000,
            "limit withdraw amount to 0.1 ether"
        );
        payable(msg.sender).transfer(_amount);
    }

    // fallback function
    receive() external payable {}
}