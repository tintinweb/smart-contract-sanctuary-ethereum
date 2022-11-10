pragma solidity ^0.5.17;

contract DeployBytecode {
    function deploy(bytes memory bytecode) public returns (address) {
        address addr;
        assembly{
            mstore(0x0, bytecode)
            addr := create(0, 0xa0, calldatasize)
        }
        return addr;
   }
}