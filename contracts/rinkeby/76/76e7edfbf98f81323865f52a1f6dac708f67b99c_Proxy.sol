/**
 *Submitted for verification at Etherscan.io on 2022-05-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBeacon {
    function implementation() external view returns (address);
}

contract Proxy {
    bytes32 constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

  
    function _getBeacon() public view returns (address) {
        return getAddressSlot(_BEACON_SLOT);
    }

    function _setBeacon(address newBeacon) public {
        assembly {
            sstore(_BEACON_SLOT, newBeacon)
        }
    }

    function getAddressSlot(bytes32 slot) internal view returns (address r) {
        assembly {
            r := sload(slot)
        }
    }

    function implementation() public view returns (address) {
        return IBeacon(_getBeacon()).implementation();
    }

    fallback() external payable {
        delegatedFwd(implementation(), msg.data);
    }
    
    
    function delegatedFwd(address _dst, bytes memory _calldata) internal {
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let result := delegatecall(
                sub(gas(), 10000),
                _dst,
                add(_calldata, 0x20),
                mload(_calldata),
                0,
                0
            )
            let size := returndatasize()
    
            let ptr := mload(0x40)
            returndatacopy(ptr, 0, size)
    
            // revert instead of invalid() bc if the underlying call failed with invalid() it already wasted gas.
            // if the call returned error data, forward it
            switch result
                case 0 {
                    revert(ptr, size)
                }
                default {
                    return(ptr, size)
                }
        }
    }
}