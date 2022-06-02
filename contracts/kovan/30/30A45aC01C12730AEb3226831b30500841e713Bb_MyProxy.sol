// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

/// @title Proxy contract for update smart contract TicTacToe
/// @author Starostin Dmitry
/// @notice getter and setter adress smart contract TicTacToe. Update smart contract TicTacToe.
/// @dev Contract under testing
contract MyProxy {
    bytes32 private constant _IMPL_SLOT = bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);

    /// @notice constructor
    /// @param implementationAddress New address of the contract
    /// @param ownerAddress msg.sender
    /// @param data msg.data
    constructor(
        address implementationAddress,
        address ownerAddress,
        bytes memory data
    ) payable {}

    /// @notice Getting the eth
    receive() external payable {
        _delegate(getAddressAt(_IMPL_SLOT));
    }

    /// @notice  Reserve function
    fallback() external payable {
        _delegate(getAddressAt(_IMPL_SLOT));
    }

    /// @notice Set the new address of contract
    /// @param _implementation New address of contract
    function setImplementation(address _implementation) external {
        setAddressAt(_IMPL_SLOT, _implementation);
    }

    /// @notice Get the new address of contract
    /// @return address Current address of contract
    function getImplementation() external view returns (address) {
        return getAddressAt(_IMPL_SLOT);
    }

    /// @notice Calling function on contract
    /// @param impl The link to the cell memory of current version of contract
    function _delegate(address impl) internal virtual {
        assembly {
            let ptr := mload(0x40) // There is a "free memory pointer" at position 0x40 in memory.
            calldatacopy(ptr, 0, calldatasize()) // copy incoming call data

            let result := delegatecall(gas(), impl, ptr, calldatasize(), 0, 0) // forward call to logic contract

            let size := returndatasize() // size answer
            returndatacopy(ptr, 0, size) // retrieve return data

            // forward return data back to caller
            switch result
            case 0 {
                revert(ptr, size)
            }
            default {
                return(ptr, size)
            }
        }
    }

    /// @notice Writing down the new address of contract version to the storage
    /// @param _slot The link to the cell memory of current version of contract
    /// @param _address The new address of current version of contract
    function setAddressAt(bytes32 _slot, address _address) private {
        assembly {
            sstore(_slot, _address) // storage[_slot] := _address
        }
    }

    /// @notice Getting the current version of contract from storage
    /// @param _slot The link to the cell memory of current version of contract
    /// @return a The address of current version of contract
    function getAddressAt(bytes32 _slot) private view returns (address a) {
        assembly {
            a := sload(_slot) // storage[_slot]
        }
    }
}