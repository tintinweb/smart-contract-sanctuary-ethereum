// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract bank {
    mapping(address => uint256) public balances;

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint256 _amount) public {
        require(balances[msg.sender] >= _amount, " withdraw anmount exceed balance");
        balances[msg.sender] -= _amount;
        (bool sent,) = msg.sender.call{value: _amount}("");
        require(sent, "sent fail");
    }
}