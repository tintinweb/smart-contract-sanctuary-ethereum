/**
 *Submitted for verification at Etherscan.io on 2022-12-24
*/

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;


contract Delegatecall {
    /**
     * Implementation address for this contract
     */
    address public implementation;
    address public owner;

    /**
     * Emitted when implementation is changed
     */
    event NewImplementation(address oldImplementation, address newImplementation);

    constructor() public {
        owner = msg.sender;
    }  

    function setImplementation(address implementation_) public {
        require(owner==msg.sender, "FORBIDDEN");
        address oldImplementation = implementation;
        implementation = implementation_;
        emit NewImplementation(oldImplementation, implementation);
    }    


    fallback() external payable {
        _fallback();
    }

    receive() external payable {
        _fallback();
    }

    function _fallback() internal {
        // delegate all other functions to current implementation
        if (msg.data.length > 0) {
            (bool success,) = implementation.delegatecall(msg.data);
            assembly {
                let free_mem_ptr := mload(0x40)
                returndatacopy(free_mem_ptr, 0, returndatasize())
                switch success
                case 0 {revert(free_mem_ptr, returndatasize())}
                default {return (free_mem_ptr, returndatasize())}
            }
        }
    }
}