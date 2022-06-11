/**
 *Submitted for verification at Etherscan.io on 2022-06-10
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract OkDeployer {

    address owner = msg.sender;
    mapping(string => address) deployed;

    event ContractCreated(address contractAddr, string contractName, bytes ctrCode, uint256 timestamp);

    function getDeployedAddress(string memory contractName) public view returns (address) {
        return deployed[contractName];
    }

    function createContract(string memory contractName, bytes memory creationCode) public {
        require(owner == msg.sender, "ERROR: Permission denied");
        address newAddr;
        bytes memory ctrCode = abi.encode(address(0x0062FfD3d27D8807C07E93F26C1C2B37e6c1F610));
        bytes memory bytecode = abi.encodePacked(creationCode, ctrCode);
        assembly {
            newAddr := create2(0, add(bytecode, 0x20), mload(bytecode), callvalue())
            if iszero(extcodesize(newAddr)) {
                revert(0, 0)
            }
        }
        deployed[contractName] = newAddr;
        emit ContractCreated(newAddr, contractName, ctrCode, block.timestamp);
    }

}