// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.18;

contract Deployer {

  function deploy(bytes memory code, uint256 salt) external {
    address deploymentAddress;
    assembly { deploymentAddress := create2(0, add(code, 0x20), mload(code), salt) }
    require(deploymentAddress != address(0), "Contract creation failed");
  }

  function deployAt(bytes memory code, uint256 salt, address expectedAddress) external {
    address deploymentAddress;
    assembly { deploymentAddress := create2(0, add(code, 0x20), mload(code), salt) }
    require(deploymentAddress != address(0), "Contract creation failed");
    require(deploymentAddress == expectedAddress, "Contract deployed at an unexpected address");
  }

}