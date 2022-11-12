// SPDX-License-Identifier: None
pragma solidity ^0.8.10;

/// @title FeeManager
/// @author Shivam Agrawal
/// @notice This contract will accumulate fees for cross-chain transactions
/// which only the relayer will be able to withdraw.
contract FeeManager {
    address public admin;

    constructor(address _relayer) {
        admin = _relayer;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin");
        _;
    }

    receive() external payable {}

    /// @notice Function to get the accumulated fees.
    /// @return accumulated fees
    function accumulatedFee() external view returns (uint256) {
        return address(this).balance;
    }

    /// @notice Function to set the address of the admin.
    /// @notice Only the admin wallet can call this function.
    /// @param _admin Address of the new admin
    function setAdmin(address _admin) external onlyAdmin {
        admin = _admin;
    }

    /// @notice Function to withdraw fees from this contract.
    /// @notice Only the admin wallet can call this function.
    /// @notice If the admin wants to withdraw all the fees, put amount = 0.
    /// @param amount Amount of fees to be withdrawn.
    function withdrawFees(uint256 amount) external onlyAdmin {
        require(amount <= address(this).balance, "amount exceeds balance");

        if (amount == 0) {
            payable(admin).transfer(address(this).balance);
        } else {
            payable(admin).transfer(amount);
        }
    }
}