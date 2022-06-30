// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "./GnosisSafeProxy.sol";

contract GetProxyAddress {
    event ProxyCreation(GnosisSafeProxy proxy, address singleton);

    /// @dev Allows to retrieve the creation code used for the Proxy deployment. With this it is easily possible to calculate predicted address.
    //用来计算create2生成的地址, 这个相当于获取合约字节码.
    function proxyCreationCode() public pure returns (bytes memory) {
        return type(GnosisSafeProxy).creationCode;
    }

    function deployProxyWithNonce(
        address _singleton,
        bytes memory initializer,
        uint256 saltNonce
    ) public returns (GnosisSafeProxy proxy, address) {
        // If the initializer changes the proxy address should change too. Hashing the initializer data is cheaper than just concatinating it
        
        bytes32 salt = keccak256(abi.encodePacked(keccak256(initializer), saltNonce));
        bytes memory deploymentData = abi.encodePacked(type(GnosisSafeProxy).creationCode, uint256(uint160(_singleton)));
        // solhint-disable-next-line no-inline-assembly
        // solhint-disable-next-line no-inline-assembly
        address predictedAddress = address(uint160(uint(keccak256(abi.encodePacked(
            bytes1(0xff),
            address(this),
            salt,
            keccak256(deploymentData)
        )))));
        assembly {
            proxy := create2(0x0, add(0x20, deploymentData), mload(deploymentData), salt)
        }
        return ( proxy, predictedAddress);
    }

    function getAddress(
        address _singleton,
        bytes memory initializer,
        uint256 saltNonce,
        address fatory
    ) public pure returns (address) {
        // If the initializer changes the proxy address should change too. Hashing the initializer data is cheaper than just concatinating it
        
        bytes32 salt = keccak256(abi.encodePacked(keccak256(initializer), saltNonce));
        bytes memory deploymentData = abi.encodePacked(type(GnosisSafeProxy).creationCode, uint256(uint160(_singleton)));
        // solhint-disable-next-line no-inline-assembly
        // solhint-disable-next-line no-inline-assembly
        address predictedAddress = address(uint160(uint(keccak256(abi.encodePacked(
            bytes1(0xff),
            fatory,
            salt,
            keccak256(deploymentData)
        )))));

        return predictedAddress;
    }
}