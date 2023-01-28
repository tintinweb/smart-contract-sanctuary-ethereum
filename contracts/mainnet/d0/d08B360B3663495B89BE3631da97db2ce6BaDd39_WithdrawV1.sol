//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

/// @title Withdraw (v1)
/// @author Kiln
/// @notice This contract is a stub contract that should be upgradeable to be adapted with future withdrawal specs
contract WithdrawV1 {
    /// @notice Retrieve the withdrawal credentials to use
    /// @return The withdrawal credentials
    function getCredentials() external view returns (bytes32) {
        return bytes32(
            uint256(uint160(address(this))) + 0x0100000000000000000000000000000000000000000000000000000000000000
        );
    }
}