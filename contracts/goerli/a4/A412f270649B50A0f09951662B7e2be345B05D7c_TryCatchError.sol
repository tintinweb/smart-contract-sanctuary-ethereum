/**
 *Submitted for verification at Etherscan.io on 2023-03-20
*/

pragma solidity 0.8.9;

contract Empty {}

contract ErrorRaiser {
    function raiseError(uint256 _errorType) external {
        if (_errorType == 0) {
            require(false);
        }
        if (_errorType == 1) {
            while(true) {
                new Empty();
            }
        }
    }
}

contract TryCatchError {
    ErrorRaiser errorRaiser;

    constructor() {
        errorRaiser = new ErrorRaiser();
    }
    function tryCatch(uint256 _errorType) external revertWhenOutOfGas returns (uint256 gasLeft, bytes memory res) {
        try errorRaiser.raiseError(_errorType) {} catch (bytes memory lowLevelRevertData) {
            gasLeft = gasleft();
            res = lowLevelRevertData;
        }
    }

    modifier revertWhenOutOfGas() {
        uint256 gasSupplied = gasleft();
        _;
        uint256 gasLeft = gasleft();
        if (gasLeft <= gasSupplied / 64) {
            revert OutOfGas(gasLeft);
        }
    }

    event CallFailed(bytes lowLevelRevertData);
    error OutOfGas(uint256 gasLeft);
}