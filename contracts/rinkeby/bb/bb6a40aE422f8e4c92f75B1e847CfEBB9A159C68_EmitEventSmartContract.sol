/**
 *Submitted for verification at Etherscan.io on 2022-07-28
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

contract EmitEventSmartContract {
    constructor() {}

    function fund() public payable {}

    event Deposit(address indexed _from, uint256 etherAmount, uint256 ts);

    function transferTo(address to_address) public {
        payable(to_address).transfer(address(this).balance);
        emit Deposit(msg.sender, address(this).balance, block.timestamp);
    }
}