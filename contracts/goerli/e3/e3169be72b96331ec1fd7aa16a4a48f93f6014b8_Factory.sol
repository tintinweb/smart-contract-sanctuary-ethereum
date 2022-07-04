pragma solidity ^0.8.10;

contract Factory {
    address owner;
    address tmpContract;

    constructor() {
        owner = msg.sender;
    }

    function changeOwner(address newowner) external {
        require(msg.sender == owner);
        owner = newowner;
    }

    function deploy(bytes memory runtimeCode, bytes32 salt) public returns(address rtnAddress) {
        require(msg.sender == owner);
        address addr;
        assembly {
            addr := create(0, add(runtimeCode, 0x20), mload(runtimeCode))
        }
        tmpContract = addr;

        bytes memory bytecode = hex"5860208158601c335a6338cc48318752fa158151803b80938091923cf3";
        assembly {
            rtnAddress := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }
    }

    function getAddress() external view returns(address) {
        return tmpContract;
    }
}