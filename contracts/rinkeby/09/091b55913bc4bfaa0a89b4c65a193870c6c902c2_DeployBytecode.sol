/**
 *Submitted for verification at Etherscan.io on 2022-05-01
*/

pragma solidity ^0.5.5;

contract DeployBytecode {
    
    // Create contract from bytecode
    event newContract(address _new);
    function deployBytecode(bytes memory bytecode) public  {
        address retval;
        assembly{
            mstore(0x0, bytecode)
            retval := create(0,0xa0, calldatasize)
        }
        emit newContract(retval);
   }
}