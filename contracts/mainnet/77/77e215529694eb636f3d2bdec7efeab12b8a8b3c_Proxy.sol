// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract Proxy {

    function calculateProxyAddress(uint256 i, bytes memory _salt) external view returns (address) {
        bytes32 bytecode = keccak256(abi.encodePacked(bytes.concat(bytes20(0x3D602d80600A3D3981F3363d3d373d3D3D363d73), bytes20(address(0x0dE8bf93dA2f7eecb3d9169422413A9bef4ef628)), bytes15(0x5af43d82803e903d91602b57fd5bf3))));
        bytes32 salt = keccak256(abi.encodePacked(_salt,i,msg.sender));
        address proxy = address(uint160(uint(keccak256(abi.encodePacked(
                    hex'ff',
                    address(0x0dE8bf93dA2f7eecb3d9169422413A9bef4ef628),
                    salt,
                    bytecode
                )))));
        return proxy;
    }
    
}