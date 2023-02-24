// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/// @dev Proxy initialization failed.
error InitializationFailed();

/// @dev Zero master tokenomics address.
error ZeroTokenomicsAddress();

/// @dev Zero tokenomics initialization data.
error ZeroTokenomicsData();

/*
* This is a proxy contract for tokenomics.
* Proxy implementation is created based on the Universal Upgradeable Proxy Standard (UUPS) EIP-1822.
* The implementation address must be located in a unique storage slot of the proxy contract.
* The upgrade logic must be located in the implementation contract.
* Special tokenomics implementation address slot is produced by hashing the "PROXY_TOKENOMICS" string in order to make
* the slot unique.
* The fallback() implementation for all the delegatecall-s is inspired by the Gnosis Safe set of contracts.
*/

/// @title TokenomicsProxy - Smart contract for tokenomics proxy
/// @author AL
/// @author Aleksandr Kuperman - <[email protected]>
contract TokenomicsProxy {
    // Code position in storage is keccak256("PROXY_TOKENOMICS") = "0xbd5523e7c3b6a94aa0e3b24d1120addc2f95c7029e097b466b2bedc8d4b4362f"
    bytes32 public constant PROXY_TOKENOMICS = 0xbd5523e7c3b6a94aa0e3b24d1120addc2f95c7029e097b466b2bedc8d4b4362f;

    /// @dev TokenomicsProxy constructor.
    /// @param tokenomics Tokenomics implementation address.
    /// @param tokenomicsData Tokenomics initialization data.
    constructor(address tokenomics, bytes memory tokenomicsData) {
        // Check for the zero address, since the delegatecall works even with the zero one
        if (tokenomics == address(0)) {
            revert ZeroTokenomicsAddress();
        }

        // Check for the zero data
        if (tokenomicsData.length == 0) {
            revert ZeroTokenomicsData();
        }

        assembly {
            sstore(PROXY_TOKENOMICS, tokenomics)
        }
        // Initialize proxy tokenomics storage
        (bool success, ) = tokenomics.delegatecall(tokenomicsData);
        if (!success) {
            revert InitializationFailed();
        }
    }

    /// @dev Delegatecall to all the incoming data.
    fallback() external {
        assembly {
            let tokenomics := sload(PROXY_TOKENOMICS)
            // Otherwise continue with the delegatecall to the tokenomics implementation
            calldatacopy(0, 0, calldatasize())
            let success := delegatecall(gas(), tokenomics, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            if eq(success, 0) {
                revert(0, returndatasize())
            }
            return(0, returndatasize())
        }
    }
}