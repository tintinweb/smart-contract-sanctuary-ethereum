pragma solidity ^0.8.10;

// (mainnet)
// (goerli)
contract Factory {
    address immutable owner;
    address tmpContract;

    constructor() {
        owner = msg.sender;
    }

    function deploy(bytes memory runtimeCode, bytes32 salt) public returns(address) {
        require(msg.sender == owner);
        address addr;
        address rtnAddress;
        
        assembly {
            addr := create(0, add(runtimeCode, 0x20), mload(runtimeCode))
        }
        tmpContract = addr;

        bytes memory bytecode = hex"5860208158601c335a6338cc48318752fa158151803b80938091923cf3";
        assembly {
            rtnAddress := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }
        return rtnAddress;
    }

    function getAddress() external view returns(address) {
        return tmpContract;
    }
}