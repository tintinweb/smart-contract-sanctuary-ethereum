/**
 *Submitted for verification at Etherscan.io on 2023-03-17
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// https://developer.arbitrum.io/arbos/precompiles
interface IArbGasInfo {
    // Get ArbOS's estimate of the L1 basefee in wei
    function getL1BaseFeeEstimate() external view returns(uint);

    // Get how slowly ArbOS updates its estimate of the L1 basefee
    function getL1BaseFeeEstimateInertia() external view returns(uint);

    // Get L1 gas fees paid by the current transaction
    function getCurrentTxL1GasFees() external view returns(uint);
}


contract ArbGasInfoViewer {
    event L1GasInfo(uint l1GasPrice, uint l1GasTotalCost);
    event Random(uint x);

    IArbGasInfo constant arbGasInfo = IArbGasInfo(address(0x6C));

    function wasteGas(uint numGas) external {
        numGas -= 21000 + 750 + 750;
        uint targetGasLeft = gasleft() - numGas;
        unchecked {
            uint x = 0xDeadBeef;
            uint MODULUS = type(uint).max;
            while(gasleft() > targetGasLeft) {
                if (gasleft() - targetGasLeft > 2600) {
                    assembly {
                        x := add(x, extcodesize(x))
                    }
                } else {
                    x = mulmod(x, x, MODULUS);
                }
            }
            emit Random(x);
        }
    }

    function _gasInfo() internal returns(uint l1GasPrice, uint l1GasTotalCost) {
        l1GasPrice = arbGasInfo.getL1BaseFeeEstimate();
        l1GasTotalCost = arbGasInfo.getCurrentTxL1GasFees();
        emit L1GasInfo(l1GasPrice, l1GasTotalCost);
        return (l1GasPrice, l1GasTotalCost);
    }

    function gasInfo0() external returns(uint l1GasPrice, uint l1GasTotalCost) {
        return _gasInfo();
    }

    function gasInfo1(uint) external returns(uint l1GasPrice, uint l1GasTotalCost) {
        return _gasInfo();
    }

    function gasInfo2(uint, uint) external returns(uint l1GasPrice, uint l1GasTotalCost) {
        return _gasInfo();
    }

    function gasInfo3(uint, uint, uint) external returns(uint l1GasPrice, uint l1GasTotalCost) {
        return _gasInfo();
    }

    fallback(bytes calldata) external returns(bytes memory) {
        uint l1GasPrice = arbGasInfo.getL1BaseFeeEstimate();
        uint l1GasTotalCost = arbGasInfo.getCurrentTxL1GasFees();
        emit L1GasInfo(l1GasPrice, l1GasTotalCost);
        return abi.encode(l1GasPrice, l1GasTotalCost);
    }
}