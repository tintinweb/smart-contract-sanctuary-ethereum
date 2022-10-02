// SPDX-License-Identifier: GPL-2.0-or-later



pragma solidity 0.4.19;

contract ETHStore {
    mapping(address => uint256) public balances;

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) public {
        require(balances[msg.sender] >= amount);
        msg.sender.call.value(amount)("");
        balances[msg.sender] -= amount;
    }

    function collectEther() public {
        msg.sender.transfer(address(this).balance);
    }

    function() external payable {}
}