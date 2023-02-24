// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/// @dev Only `owner` has a privilege, but the `sender` was provided.
/// @param sender Sender address.
/// @param owner Required sender address as an owner.
error OwnerOnly(address sender, address owner);

/// @dev Provided zero address.
error ZeroAddress();

/// @dev Wrong length of two arrays.
/// @param numValues1 Number of values in a first array.
/// @param numValues2 Number of values in a second array.
error WrongArrayLength(uint256 numValues1, uint256 numValues2);

/// @title DonatorBlacklist - Smart contract for donator address blacklisting
/// @author AL
/// @author Aleksandr Kuperman - <[email protected]>
contract DonatorBlacklist {
    event OwnerUpdated(address indexed owner);
    event DonatorBlacklistStatus(address indexed account, bool status);

    // Owner address
    address public owner;
    // Mapping account address => blacklisting status
    mapping(address => bool) public mapBlacklistedDonators;

    /// @dev DonatorBlacklist constructor.
    constructor() {
        owner = msg.sender;
    }

    /// @dev Changes the owner address.
    /// @param newOwner Address of a new owner.
    function changeOwner(address newOwner) external {
        // Check for the contract ownership
        if (msg.sender != owner) {
            revert OwnerOnly(msg.sender, owner);
        }

        // Check for the zero address
        if (newOwner == address(0)) {
            revert ZeroAddress();
        }

        owner = newOwner;
        emit OwnerUpdated(newOwner);
    }

    /// @dev Controls donators blacklisting statuses.
    /// @notice Donator is considered blacklisted if its status is set to true.
    /// @param accounts Set of account addresses.
    /// @param statuses Set blacklisting statuses.
    /// @return success True, if the function executed successfully.
    function setDonatorsStatuses(address[] memory accounts, bool[] memory statuses) external returns (bool success) {
        // Check for the contract ownership
        if (msg.sender != owner) {
            revert OwnerOnly(msg.sender, owner);
        }

        // Check for the array length
        if (accounts.length != statuses.length) {
            revert WrongArrayLength(accounts.length, statuses.length);
        }

        for (uint256 i = 0; i < accounts.length; ++i) {
            // Check for the zero address
            if (accounts[i] == address(0)) {
                revert ZeroAddress();
            }
            // Set the account blacklisting status
            mapBlacklistedDonators[accounts[i]] = statuses[i];
            emit DonatorBlacklistStatus(accounts[i], statuses[i]);
        }
        success = true;
    }

    /// @dev Gets account blacklisting status.
    /// @param account Account address.
    /// @return status Blacklisting status.
    function isDonatorBlacklisted(address account) external view returns (bool status) {
        status = mapBlacklistedDonators[account];
    }
}