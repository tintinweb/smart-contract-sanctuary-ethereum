/**
 *Submitted for verification at Etherscan.io on 2023-02-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;
//Use Create2 to know contract address before it is deployed.
contract DeployWithCreate2 {
    address public owner;
    constructor(address _owner) {
        owner = _owner;
    }
}
contract Create2Factory {
    event Deploy(address addr);
    // to deploy another contract using owner address and salt specified
    function deploy(uint _salt) external {
        DeployWithCreate2 _contract = new DeployWithCreate2{
            salt: bytes32(_salt)    // the number of salt determines the address of the contract that will be deployed
        }(msg.sender);
        emit Deploy(address(_contract));
    }

    // get the computed address before the contract DeployWithCreate2 deployed using Bytecode of contract DeployWithCreate2 and salt specified by the sender
    function getAddress(bytes memory bytecode, uint _salt) public view returns (address) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff), address(this), _salt, keccak256(bytecode)
            )
        );
        return address (uint160(uint(hash)));
    }
    // get the ByteCode of the contract DeployWithCreate2
    function getBytecode(address _owner) public pure returns (bytes memory) {
        bytes memory bytecode = type(DeployWithCreate2).creationCode;
        return abi.encodePacked(bytecode, abi.encode(_owner));
    }
}