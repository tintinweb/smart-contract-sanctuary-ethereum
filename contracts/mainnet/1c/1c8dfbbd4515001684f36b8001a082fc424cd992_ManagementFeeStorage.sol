// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

contract ManagementFeeStorage {
    address public manager;
    uint256 platformFee;

    constructor(uint256 _platformFee){
        manager = msg.sender;
        platformFee = _platformFee;
    }

    modifier onlyManager {
        require(msg.sender == manager, "Not Authorized");
        _;
    }

    /// @dev Function to set manager of the storage.
    /// @param _manager Address of the new manager.
    function setManager(address _manager) external onlyManager {
        manager = _manager;
    }

    /// @dev Function to get percentage of the fee that goes to the platform.
    function getPlatformFee() external view returns (uint256) {
        return platformFee;
    }

    /// @dev Function to set percentage of the fee that goes to the platform.
    /// @param _platformFee Percentage of the fee that goes to the platform.
    function setPlatformFee(uint256 _platformFee) external onlyManager {
        platformFee = _platformFee;
    }

}