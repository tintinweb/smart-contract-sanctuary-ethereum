// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface ICreate2Deployer {

    event Deployed(address addr, uint256 salt);

    function predictDeployAddress(bytes memory code, uint256 salt) external view returns (address addr);
    function deploy(bytes memory code, uint256 salt) external returns (address addr);
}

contract KEICreate2Deployer is ICreate2Deployer {

    string public constant name = "Kei Finance";
    string public constant url = "https://kei.fi";

    function predictDeployAddress(bytes memory bytecode, uint256 salt) external view returns (address addr) {
        bytes32 hash = keccak256(
            abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(bytecode))
        );
        return address(uint160(uint256(hash)));
    }

    function deploy(bytes memory bytecode, uint256 salt) external returns (address addr) {
        assembly {
            addr := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
        emit Deployed(addr, salt);
    }
}