/**
 *Submitted for verification at Etherscan.io on 2023-02-02
*/

pragma solidity ^0.8.17;

contract CloneFactory {
    /**
     * @dev Creates a clone of the logic contract.
     * 
     * @param logicContractAddress The address of the logic contract to be cloned.
     * @return result The address of the newly created clone contract.
     */
    function createClone(address logicContractAddress) external returns(address result){
        bytes20 addressBytes = bytes20(logicContractAddress);
        assembly{
            let clone:= mload(0x40) // Jump to the end of the currently allocated memory- 0x40 is the free memory pointer. It allows us to add own code
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000) // store 32 bytes (0x3d602...) to memory starting at the position clone
            mstore(add(clone, 0x14), addressBytes) // add the address at the location clone + 20 bytes. 0x14 is hexadecimal and is 20 in decimal
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000) // add the rest of the code at position 40 bytes (0x28 = 40)
            result := create(0, clone, 0x37)
        }
    }
}