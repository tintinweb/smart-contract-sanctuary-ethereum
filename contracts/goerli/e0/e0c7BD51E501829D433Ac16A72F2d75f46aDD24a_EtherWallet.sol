// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

error NotOwner(address caller);
error FailedWithdraw();

contract EtherWallet {
    address public s_owner;
    uint256 public s_balance;

    event FundsReceived(uint256 indexed amount);
    event FundsWithdrew(uint256 indexed amount);
    event OwnershipTransfered(address indexed newOwner);

    constructor() {
        s_owner = payable(msg.sender);
    }

    receive() external payable {
        s_balance += msg.value;

        emit FundsReceived(msg.value);
    }

    function withdraw(uint256 _amount) external onlyOwner {
        (bool success, ) = msg.sender.call{value: _amount}("");
        if (!success) {
            revert FailedWithdraw();
        }

        s_balance -= _amount;

        emit FundsWithdrew(_amount);
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        s_owner = _newOwner;

        emit OwnershipTransfered(_newOwner);
    }

    modifier onlyOwner() {
        if (msg.sender != s_owner) {
            revert NotOwner(msg.sender);
        }
        _;
    }
}