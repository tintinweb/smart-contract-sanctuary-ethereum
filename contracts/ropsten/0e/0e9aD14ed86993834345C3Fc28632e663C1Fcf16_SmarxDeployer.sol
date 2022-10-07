/**
 *Submitted for verification at Etherscan.io on 2022-10-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.4.21;

contract SmarxDeployer {
    event FoundOne(address);
    
    function deploySmarx(bytes memory code, uint256 salt) public returns(address) {
        address addr;
        assembly {
          addr := create2(0, add(code, 0x20), mload(code), salt)
          if iszero(extcodesize(addr)) {
            revert(0, 0)
          }
        }
        
        emit FoundOne(addr);
        return addr;
    }
}