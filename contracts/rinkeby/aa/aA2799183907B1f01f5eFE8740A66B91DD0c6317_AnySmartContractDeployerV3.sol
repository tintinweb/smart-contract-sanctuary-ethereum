// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract AnySmartContractDeployerV3 {
  bytes defaultContractBytecode = hex"6080604052348015600f57600080fd5b50603e80601d6000396000f3fe6080604052600080fdfea265627a7a7231582038266ad578d4e92225c15b8843fb6eab963c1463aa51f7a130b8ca820fb1acd964736f6c63430005100032";
  address lastDeployment;
    function deployNew(uint256 valueInWei, bytes32 salt, bytes memory contractBytecode) public returns(address deployed ) {
        bytes memory bytecode = defaultContractBytecode;
        if (contractBytecode.length != 0) {
            bytecode = contractBytecode;
        }
        address addr;
        assembly {
            addr := create2(valueInWei, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Should have valid addr from deployment");
        lastDeployment = addr;
        return addr;
    }

    function deployDefault(bytes32 salt) public returns(address deployed ) {
        bytes memory bytecode = defaultContractBytecode;
        address addr;
        assembly {
            addr := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Should have valid addr from deployment");
        lastDeployment = addr;
        return addr;
    }

    function getLastDeployAddress() public view returns(address) {
        return lastDeployment;
    }
}