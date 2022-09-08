/**
 *Submitted for verification at Etherscan.io on 2022-09-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

library StorageSlot {
    function getAddress(bytes32 slot) internal view returns (address a) {
        assembly {
            a := sload(slot)
        }
    }

    function setAddress(bytes32 slot, address address_) internal {
        assembly {
            sstore(slot, address_)
        }
    }
}

//Proxy contract a pointer to our implementation contracts  for upgrading
contract Proxy {
    using StorageSlot for bytes32;

    bytes32 private constant _IMPL_SLOT =
        bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);

    function setImplementation(address implementation_) public {
        _IMPL_SLOT.setAddress(implementation_);
    }

    function getImplementation() public view returns (address) {
        return _IMPL_SLOT.getAddress();
    }

    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    fallback() external {
        _delegate(getImplementation());
    }
    
}