/**
 *Submitted for verification at Etherscan.io on 2023-05-25
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract Create2Deployer {
    error DeployFailed();
    error CallFailed();

    event Deployed(address index);

    function deploy(uint256 salt, bytes memory initCode, bytes memory calldata_)
        external
        payable
        returns (address)
    {
        address addr;

        assembly {
            addr := create2(callvalue(), add(initCode, 0x20), mload(initCode), salt)
        }

        if (addr == address(0)) revert DeployFailed();

        if (calldata_.length > 0) {
            (bool success,) = addr.call(calldata_);
            if (!success) revert CallFailed();
        }

        emit Deployed(addr);

        return addr;
    }

    function computeDeterministicAddress(uint256 salt, bytes memory initCode)
        external
        view
        returns (address)
    {
        return address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(initCode))
                    )
                )
            )
        );
    }
}