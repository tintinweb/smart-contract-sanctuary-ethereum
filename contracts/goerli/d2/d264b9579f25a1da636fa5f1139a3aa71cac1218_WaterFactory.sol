/**
 *Submitted for verification at Etherscan.io on 2023-01-12
*/

// File: Demo/WaterFactory.sol



pragma solidity ^0.8.7;

contract WaterFactory {
    event ContractDeployed(bytes32 salt, address addr);

    function deployContract(bytes32 salt, bytes memory bytecode) public returns (address addr) {
        assembly {
            addr := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
            if iszero(extcodesize(addr)) { revert(0, 0) }
        }
        emit ContractDeployed(salt, addr);
    }

    function deployContractWithConstructor(bytes32 salt, bytes memory bytecode, bytes memory constructorArgs) public returns (address addr) {
        bytes memory payload = abi.encodePacked(bytecode, constructorArgs);
        assembly {
            addr := create2(0, add(payload, 0x20), mload(payload), salt)
            if iszero(extcodesize(addr)) { revert(0, 0) }
        }
        emit ContractDeployed(salt, addr);
    }
}

// contract Factory is Context{
//     function deploy(bytes32 _salt) public payable returns (address) {
//         return address(new Water{salt: _salt}(_msgSender()));
//     }
// }