/**
 *Submitted for verification at Etherscan.io on 2023-01-11
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

contract DeployAny {
    error DeployAny__deployContractfailed();

    /**
     * @notice Deploys an arbitrary Contract.
     * @param creationCode The encoded data containing asset, debtAsset and oracle.
     * @param args The encoded constructor arguments: abi.encode(arg1,arg2,...)
     * @param salt desired
     */
    function deployContract(
        bytes memory creationCode,
        bytes memory args,
        uint256 salt
    ) external returns (address contract_) {
        bytes memory bytecode = abi.encodePacked(creationCode, args);

        assembly {
            contract_ := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        if (contract_ == address(0)) revert DeployAny__deployContractfailed();
    }

    /**
     * @notice Returns the expected address for deploying contract.
     * @param creationCode The encoded data containing asset, debtAsset and oracle.
     * @param args The encoded constructor arguments: abi.encode(arg1,arg2,...)
     * @param salt desired
     */
    function getAddress(
        bytes memory creationCode,
        bytes memory args,
        uint256 salt
    ) public view returns (address) {
        bytes memory bytecode = abi.encodePacked(creationCode, args);
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                salt,
                keccak256(bytecode)
            )
        );
        return address(uint160(uint256(hash)));
    }

    /**
     * @notice Returns the bytecode of a deployed contract in `contract_`.
     * @param contract_ address to retrieve bytecode
     */
    function getBytecode(address contract_) public view returns (bytes memory bytecode) {
        bytecode = contract_.code;
    }

}