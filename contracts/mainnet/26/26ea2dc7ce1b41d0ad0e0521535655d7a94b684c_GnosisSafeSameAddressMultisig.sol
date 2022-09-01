// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

// Gnosis Safe Master Copy interface extracted from the mainnet: https://etherscan.io/address/0xd9db270c1b5e3bd161e8c8503c55ceabee709552#code#F6#L126
interface IGnosisSafe {
    /// @dev Gets set of owners.
    /// @return Set of Safe owners.
    function getOwners() external view returns (address[] memory);

    /// @dev Gets threshold.
    /// @return Threshold
    function getThreshold() external view returns (uint256);
}

/// @dev Provided incorrect data length.
/// @param expected Expected minimum data length.
/// @param provided Provided data length.
error IncorrectDataLength(uint256 expected, uint256 provided);

/// @dev Provided incorrect multisig threshold.
/// @param expected Expected threshold.
/// @param provided Provided threshold.
error WrongThreshold(uint256 expected, uint256 provided);

/// @dev Provided incorrect number of owners.
/// @param expected Expected number of owners.
/// @param provided Provided number of owners.
error WrongNumOwners(uint256 expected, uint256 provided);

/// @dev Provided incorrect multisig owner.
/// @param provided Provided owner address.
error WrongOwner(address provided);

/// @dev Multisig transaction resulted in a failure.
/// @param provided Provided multisig address.
error MultisigExecFailed(address provided);

/// @title Gnosis Safe Same Address - Smart contract for Gnosis Safe verification of an already existent multisig address.
/// @author Aleksandr Kuperman - <[email protected]>
contract GnosisSafeSameAddressMultisig {
    // Default data size to be parsed as an address of a Gnosis Safe multisig proxy address
    // This exact size suggests that all the changes to the multisig have been performed and only validation is needed
    uint256 public constant DEFAULT_DATA_LENGTH = 20;

    /// @dev Updates and/or verifies the existent gnosis safe multisig for changed owners and threshold.
    /// @notice This function operates with existent multisig proxy that is requested to be updated in terms of
    ///         the set of owners' addresses and the threshold. There are two scenarios possible:
    ///         1. The multisig proxy is already updated before reaching this function. Then the multisig address
    ///            must be passed as a payload such that its owners and threshold are verified against those specified
    ///            in the argument list.
    ///         2. The multisig proxy is not yet updated. Then the multisig address must be passed in a packed bytes of
    ///            data along with the Gnosis Safe `execTransaction()` function arguments packed payload. That payload
    ///            is going to modify the mulsisig proxy as per its signed transaction. At the end, the updated multisig
    ///            proxy is going to be verified with the provided set of owners' addresses and the threshold.
    ///         Note that owners' addresses in the multisig are stored in reverse order compared to how they were added:
    ///         https://etherscan.io/address/0xd9db270c1b5e3bd161e8c8503c55ceabee709552#code#F6#L56
    /// @param owners Set of updated multisig owners to verify against.
    /// @param threshold Updated number for multisig transaction confirmations.
    /// @param data Packed data containing address of an existent gnosis safe multisig and a payload to call the multisig with.
    /// @return multisig Address of a multisig (proxy).
    function create(
        address[] memory owners,
        uint256 threshold,
        bytes memory data
    ) external returns (address multisig)
    {
        // Check for the correct data length
        uint256 dataLength = data.length;
        if (dataLength < DEFAULT_DATA_LENGTH) {
            revert IncorrectDataLength(DEFAULT_DATA_LENGTH, data.length);
        }

        // Read the proxy multisig address (20 bytes) and the multisig-related data
        assembly {
            multisig := mload(add(data, DEFAULT_DATA_LENGTH))
        }

        // If provided, read the payload that is going to change the multisig ownership and threshold
        // The payload is expected to be the `execTransaction()` function call with all its arguments and signature(s)
        if (dataLength > DEFAULT_DATA_LENGTH) {
            uint256 payloadLength = dataLength - DEFAULT_DATA_LENGTH;
            bytes memory payload = new bytes(payloadLength);
            for (uint256 i = 0; i < payloadLength; ++i) {
                payload[i] = data[i + DEFAULT_DATA_LENGTH];
            }

            // Call the multisig with the provided payload
            (bool success, ) = multisig.call(payload);
            if (!success) {
                revert MultisigExecFailed(multisig);
            }
        }

        // Get the provided proxy multisig owners and threshold
        address[] memory checkOwners = IGnosisSafe(multisig).getOwners();
        uint256 checkThreshold = IGnosisSafe(multisig).getThreshold();

        // Verify updated multisig proxy for provided owners and threshold
        if (threshold != checkThreshold) {
            revert WrongThreshold(checkThreshold, threshold);
        }
        uint256 numOwners = owners.length;
        if (numOwners != checkOwners.length) {
            revert WrongNumOwners(checkOwners.length, numOwners);
        }
        // The owners' addresses in the multisig itself are stored in reverse order compared to how they were added:
        // https://etherscan.io/address/0xd9db270c1b5e3bd161e8c8503c55ceabee709552#code#F6#L56
        // Thus, the check must be carried out accordingly.
        for (uint256 i = 0; i < numOwners; ++i) {
            if (owners[i] != checkOwners[numOwners - i - 1]) {
                revert WrongOwner(owners[i]);
            }
        }
    }
}