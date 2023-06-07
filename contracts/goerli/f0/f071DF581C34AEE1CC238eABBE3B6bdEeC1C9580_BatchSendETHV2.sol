// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BatchSendETHV2 {
    function sendFee(
        address payable[] memory _batchAddresses,
        uint256 feeAmount
    ) external payable {
        require(
            msg.value >= feeAmount * _batchAddresses.length,
            "Insufficient fee amount"
        );

        for (uint256 i = 0; i < _batchAddresses.length; i++) {
            _batchAddresses[i].transfer(feeAmount);
        }
    }

    function withdraw(uint256 amount) external {
        require(
            amount <= address(this).balance,
            "Insufficient contract balance"
        );

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Failed to withdraw");
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}