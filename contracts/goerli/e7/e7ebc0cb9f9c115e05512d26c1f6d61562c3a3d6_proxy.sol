/**
 *Submitted for verification at Etherscan.io on 2022-04-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract proxy {
    event log(string  values);

    bytes32 internal constant IMPLEMENTATION_SLOT =keccak256("DEMO.20220415.implemntation-slot");

    function implementation() public view returns (address _implementation) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            _implementation := sload(slot)
        }
    }

    function setImplementation(address newImplementation) public  virtual   {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            sstore(slot, newImplementation)
        }
    }

    fallback () external payable virtual {
        address _implementation = implementation();
        require(_implementation != address(0x0), "MISSING_IMPLEMENTATION");
        emit log("in Impl fallback");
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), _implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

}