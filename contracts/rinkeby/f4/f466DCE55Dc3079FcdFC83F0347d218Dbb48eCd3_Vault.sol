//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract Vault {
    address public owner;
    uint256 public balance;
    uint256 public userCount;

    event LockETH(
        address indexed ethAddress,
        string algoAddress,
        uint256 amount
    );
    event UnlockETH(address indexed ethAddress, uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    function lockETH(string calldata _algoAddress)
        external
        payable
        returns (uint256 _id)
    {
        require(msg.value > 1000000000, "Sending amount is too small!");

        balance += msg.value;
        userCount++;

        emit LockETH(msg.sender, _algoAddress, msg.value);

        return userCount;
    }

    function unlockETH(address _ethAddress, uint256 _amount) external {
        require(msg.sender == owner, "You are not the owner!");

        require(balance > 0, "Balance is zero!");
        require(balance >= _amount, "Balance is not enough to withdraw!");

        (bool sent, ) = _ethAddress.call{value: _amount}("");
        require(sent, "Failed to send ETH!");

        balance -= _amount;

        emit UnlockETH(msg.sender, _amount);
    }
}