pragma solidity ^0.5.10;
contract Deployer {
    bytes public deployBytecode;
    address public deployedAddr;
    event Transfer(uint);
    function deploy() public returns (uint){
        emit Transfer(3);
        return 3;
    }
}