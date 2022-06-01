// SPDX-License-Identifier: None
pragma solidity ^0.8.9;

contract SmartWallet {
    event Deposit(address indexed sender, uint256 amount);

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function execute(
        address to,
        bytes calldata callData,
        uint256 value
    ) external returns (bool txStatus, bytes memory data) {
        (bool success, bytes memory txData) = to.call{value: value}(callData);
        require(success, "tx failed");
        return (success, txData);
    }
}