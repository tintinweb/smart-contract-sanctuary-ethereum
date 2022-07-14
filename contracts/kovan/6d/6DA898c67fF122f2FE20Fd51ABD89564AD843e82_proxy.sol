/**
 *Submitted for verification at Etherscan.io on 2022-06-24
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract Implementation  {
    uint256 public constant y = 68719149055;
    uint256 public immutable z;
    uint256 public x;
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(uint256 _z) {
        z = _z;
    }

    function initialize() public {
        x = 5;
    }

    function getY() public pure returns (uint256) {
        return y;
    }

    function getYY() public pure returns (uint256) {
        return y;
    }

    function getZ() public view returns (uint256) {
        return z;
    }

    function getZZ() public view returns (uint256) {
        return z;
    }
}

contract proxy {
    Implementation public impl;

    function createConcreat() external {
        impl = new Implementation(5);
        impl.y();
    }

    function initialize() external {
        impl.initialize();
    }

    function x() external view returns (uint256) {
        return impl.x();
    }

    function deploy(bytes calldata _bytecode) external returns(address addr) {

        bytes memory bytecode = abi.encode(_bytecode, msg.sender);
        assembly {
            addr := create(0, add(bytecode, 0x20), mload(bytecode))
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
    }
}