/**
 *Submitted for verification at Etherscan.io on 2022-10-27
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract Create2Factory {

    event create2Event(address deployedAddressEvent);

    function generalDeployCreate2(uint _salt, bytes memory creationCode) public { // BYTECODE NEEDS TO HAVE "0X" PREFIX TO BUILD RLP!
        address deployedAddress;     // Salt example:         0x0000000000000000000000000000000000000000000000000000000000000000
        assembly {                   // Another salt example: 0x123456789abcdef0000000000000000000000000000000000000000000000000
            deployedAddress := create2(0, add(creationCode, 0x20), mload(creationCode), _salt) //callvalue() is the same as msg.value in assembly. callvalue() == 0 to save gas since the constructor and this create2 function are not payable.
            if iszero(extcodesize(deployedAddress)) { //Note: constructor is not payable and takes no input variables (hardcoded in) to keep the creation code simple for this example.
                revert(0, 0)                           
            }
        }
        emit create2Event(deployedAddress);
    }

    function generalPrecomputeAddress(uint _salt, bytes memory creationCode) public view returns (address) { // BYTECODE NEEDS TO HAVE "0X" PREFIX TO BUILD RLP!
        bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), address(this), _salt, keccak256(creationCode)));
        return address(uint160(uint(hash)));
    }

}