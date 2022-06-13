// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract CommitEther {
    event Deposit(address from, uint256 amount);
    event Withdraw(address to, uint256 amount);

    uint256 public balanceReceived;
    uint256 public balanceWithdrawed;

    address public owner = msg.sender;

    receive() external payable {
        balanceReceived += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdraw(uint256 amount) external {
        require(msg.sender == owner, "Caller is not owner");
        require(amount <= getBalance(), "Contract doesn't own enough eth");
        address payable _to = payable(msg.sender);
        _to.transfer(amount);
        balanceWithdrawed += amount;
        emit Withdraw(_to, getBalance());
    }

    function withdrawAll() external {
        require(msg.sender == owner, "Caller is not owner");
        address payable _to = payable(msg.sender);
        uint256 balance = getBalance();
        _to.transfer(balance);
        balanceWithdrawed += balance;
        emit Withdraw(_to, getBalance());
    }

    function withdrawTo(address payable _to, uint256 amount) external {
        require(msg.sender == owner, "Caller is not owner");
        require(amount <= getBalance(), "Contract doesn't own enough eth");
        _to.transfer(amount);
        balanceWithdrawed += amount;
        emit Withdraw(_to, amount);
    }
}