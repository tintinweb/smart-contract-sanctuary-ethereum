//SPDX-License-Identifier:MIT
pragma solidity ^0.8.13;

contract Swap {
    address public voyagerDepositHandler;
    // depositReserveToken(bool,bytes,bytes)
    bytes4 public constant DEPOSIT_RESERVE_SELECTOR = 0x3a139384;
    // depositNonReserveToken(bool,bytes,bytes)
    bytes4 public constant DEPOSIT_NON_RESERVE_SELECTOR = 0x0ae79779;
    // depositLPToken(bytes,bytes)
    bytes4 public constant DEPOSIT_LP_SELECTOR = 0xb78802d9;

    function callVoyager(bytes4 depositFunctionSelector, bytes calldata _data)
        public
    {
        voyagerDepositHandler = msg.sender;
        bool success;
        bytes memory data;
        if (
            depositFunctionSelector == DEPOSIT_RESERVE_SELECTOR ||
            depositFunctionSelector == DEPOSIT_NON_RESERVE_SELECTOR
        ) {
            (
                bool isSourceNative,
                bytes memory swapData,
                bytes memory executeData
            ) = abi.decode(_data, (bool, bytes, bytes));
            (success, data) = voyagerDepositHandler.call(
                abi.encodeWithSelector(
                    depositFunctionSelector,
                    isSourceNative,
                    swapData,
                    executeData
                )
            );
        } else if (depositFunctionSelector == DEPOSIT_LP_SELECTOR) {
            (bytes memory swapData, bytes memory executeData) = abi.decode(
                _data,
                (bytes, bytes)
            );
            (success, data) = voyagerDepositHandler.call(
                abi.encodeWithSelector(
                    DEPOSIT_LP_SELECTOR,
                    swapData,
                    executeData
                )
            );
        }

        require(success == true, "Voyager deposit failed");
    }
}