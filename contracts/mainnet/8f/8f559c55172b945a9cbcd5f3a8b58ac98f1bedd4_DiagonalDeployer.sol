// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

import { IDiagonalDeployer } from "../interfaces/auxiliary/IDiagonalDeployer.sol";

/**
 * @title  DiagonalDeployer contract
 * @author Diagonal Finance
 */
contract DiagonalDeployer is IDiagonalDeployer {
    /// @inheritdoc IDiagonalDeployer
    function deploy(bytes memory code, uint256 salt) external override returns (address addr) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            addr := create2(0, add(code, 0x20), mload(code), salt)
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }

        emit Deployed(addr, salt);
    }

    /// @inheritdoc IDiagonalDeployer
    function getAddress(bytes memory code, uint256 salt) external view override returns (address addr) {
        bytes32 _hash = keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(code)));
        addr = address(uint160(uint256(_hash)));
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

/**
 * @title IDiagonalDeployer contract interface
 * @author Diagonal Finance
 * @notice DiagonalDeployer handles the deployment of all Diagonal contracts
 */
interface IDiagonalDeployer {
    /**
     * @notice Emitted when contract deployed
     * @param addr The address of the deployed contract
     * @param salt The salt used
     */
    event Deployed(address addr, uint256 salt);

    /**
     * @notice Deploys contract using CREATE2
     * @param code The bytecode of the contract
     * @param salt The salt used
     * @return addr The address of the contract
     */
    function deploy(bytes memory code, uint256 salt) external returns (address addr);

    /**
     * @notice Returns the address from `deploy(code, salt)`, without deploying
     * @param code The bytecode of the contract
     * @param salt The salt used
     * @return addr The address of the contract
     */
    function getAddress(bytes memory code, uint256 salt) external view returns (address addr);
}