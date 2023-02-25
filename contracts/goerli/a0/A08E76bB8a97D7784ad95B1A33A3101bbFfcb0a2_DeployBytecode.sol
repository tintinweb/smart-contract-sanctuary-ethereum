/**
 *Submitted for verification at Etherscan.io on 2023-02-25
*/

pragma solidity ^0.8.18;

contract DeployBytecode {
    event NewContractDeployed (address newContract);

    function deployFromBytecode(bytes memory bytecode) public {
        address child;
        assembly{
            mstore(0x0, bytecode)
            child := create(0,0xa0, calldatasize())
        }
        emit NewContractDeployed(child);
   }
}