// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title TreasuryMock
/// @dev Only relevant for unit testing
contract TreasuryMock {
    /// @notice Function to receive Ether. msg.data must be empty
    receive() external payable {}

    /// @notice Fallback function is called when msg.data is not empty
    fallback() external payable {}

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}