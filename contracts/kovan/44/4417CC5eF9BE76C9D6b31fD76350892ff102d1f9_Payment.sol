//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Payment {
    mapping(address => uint256) public balances;

    event PaymentAdded(address user, uint256 amount, uint256 timestamp);

    function fundMe() public payable {
        require(msg.value > 0, "Where's the ETH!!!!!!!!");
        balances[msg.sender] += msg.value;
        emit PaymentAdded(msg.sender, msg.value, block.timestamp);
    }
}