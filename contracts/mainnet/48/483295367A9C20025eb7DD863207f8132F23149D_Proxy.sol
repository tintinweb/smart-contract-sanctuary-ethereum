// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract Proxy {

    function calculateProxyAddress(uint256[] calldata a, bytes memory _salt, address cointoolAddress) external view returns (address [] memory) {
        bytes32 bytecode = keccak256(abi.encodePacked(bytes.concat(bytes20(0x3D602d80600A3D3981F3363d3d373d3D3D363d73), bytes20(cointoolAddress), bytes15(0x5af43d82803e903d91602b57fd5bf3))));
        uint256 i = 0;
        address[] memory proxy = new address[](a.length);
        for (i; i<a.length; i++) {
            bytes32 salt = keccak256(abi.encodePacked(_salt,a[i],msg.sender));
            proxy[i] = address(uint160(uint(keccak256(abi.encodePacked(
                    hex'ff',
                    cointoolAddress,
                    salt,
                    bytecode
                )))));
        }
        
        return proxy;
    }
    
}