// SPDX-License-Identifier: GPL-2.0-or-later



pragma solidity 0.7.6;

contract ETHStore {
    mapping(address => uint256) public balances;

    event Deposit(address indexed user, uint256 indexed amount);

    event Withdraw(address indexed user, uint256 indexed amount);

    function deposit() public payable {
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) public {
        require(balances[msg.sender] >= amount, "balance not En");
        payable(msg.sender).call{ value: amount };
        balances[msg.sender] -= amount;
        emit Withdraw(msg.sender, amount);
    }

    function withdraw1(uint256 amount) public {
        require(balances[msg.sender] >= amount, "balance not En");
        payable(msg.sender).call{ value: amount }("");
        balances[msg.sender] -= amount;
        emit Withdraw(msg.sender, amount);
    }

    function collectEther() public {
        msg.sender.transfer(address(this).balance);
    }

    receive() external payable {}

    fallback() external {}
}