/**
 *Submitted for verification at Etherscan.io on 2022-04-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

contract Proxy {


  /**
  * @dev Tells the address of the implementation where every call will be delegated.
  * @return address of the implementation to which it will be delegated
  */
    function implementation() public view returns (address){
        return 0xfDb61FB43e2e3B5A19B26Ff17eabd1c3D2110360;
    }


    fallback() external payable {
        address _impl = 0xfDb61FB43e2e3B5A19B26Ff17eabd1c3D2110360;
        require(_impl != address(0x0), "MISSING_IMPLEMENTATION");

        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 for now, as we don't know the out size yet.
            let result := delegatecall(gas(), _impl, 0, calldatasize(), 0, 0)

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
}