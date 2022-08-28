/**
 *Submitted for verification at Etherscan.io on 2022-08-28
*/

pragma solidity ^0.5.5;

contract DeployBytecode {
    
    // Create contract from bytecode
    function deployBytecode(bytes memory bytecode) public returns (address) {
        address retval;
        assembly{
            mstore(0x0, bytecode)
            retval := create(0,0xa0, calldatasize)
        }
        return retval;
   }
}