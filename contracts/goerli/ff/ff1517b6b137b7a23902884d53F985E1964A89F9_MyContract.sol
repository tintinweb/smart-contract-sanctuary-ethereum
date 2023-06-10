/**
 *Submitted for verification at Etherscan.io on 2023-06-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyContract {
    bytes constant public additionalInfo = hex"000000000000000000000000000000000000000000000000000000000000000C000000000000000000000000DD9F01B1EC0055B48525C56B1AE73118238CD7BF0000000000000000000000000000000000000000000000000000000000000003";

    bytes32 constant public txHash = hex"717d4d908669451cae24b5a5a78ce59449db5d091112eef71704189adcadcdc6";

    uint256 constant public payment = 0;

    function execTransaction(
        address to,
        uint256 value,
        bytes memory data,
        uint8 operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address refundReceiver,
        bytes memory signatures
    ) external returns (bool) {
        // Perform the desired operations here
        // For demonstration purposes, we're just emitting an event
        emit SafeMultiSigTransaction(to, value, data, operation, safeTxGas, baseGas, gasPrice, gasToken, refundReceiver, signatures, additionalInfo);

        emit ExecutionSuccess(txHash, payment);

        // Return true to indicate the successful execution of the transaction
        return true;
    }

    // event TransactionExecuted(
    //     address to,
    //     uint256 value,
    //     bytes data,
    //     uint8 operation,
    //     uint256 safeTxGas,
    //     uint256 baseGas,
    //     uint256 gasPrice,
    //     address gasToken,
    //     address refundReceiver,
    //     bytes signatures
    // );

    event SafeMultiSigTransaction(
        address to,
        uint256 value,
        bytes data,
        uint8 operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address refundReceiver,
        bytes signatures,
        bytes additionalInfo
    );

    event ExecutionSuccess(
        bytes32 txHash,
        uint256 payment
    );
}