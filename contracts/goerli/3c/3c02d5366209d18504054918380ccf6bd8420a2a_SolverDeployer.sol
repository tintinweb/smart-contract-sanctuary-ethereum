// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

contract SolverDeployer {
    bytes5 public constant storeResultInMemory = 0x602a608052;
    bytes5 public constant returnStoredValue = 0x60206080f3;
    bytes7 public constant copyCode = 0x600a600c600039;
    bytes5 public constant returnCodeToEVM = 0x600a6000f3;

    /// @notice Check the returned address in the deployment transaction
    function deployNewSolver() external returns (address addr) {
        bytes memory bytecode = bytes.concat(initBytecode(), runtimeBytecode());
        assembly {
            addr := create(0, add(bytecode, 32), mload(bytecode))
        }
    }

    function runtimeBytecode() public pure returns (bytes10) {
        return bytes10(bytes.concat(storeResultInMemory, returnStoredValue));
    }

    function initBytecode() public pure returns (bytes12) {
        return bytes12(bytes.concat(copyCode, returnCodeToEVM));
    }
}