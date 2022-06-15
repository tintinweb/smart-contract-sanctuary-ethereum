// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// found issue with transfer fee tokens
contract DEXManagement {
    event LogReceived(address indexed, uint256);
    event LogFallback(address indexed, uint256);

    constructor() {}

    struct FillResults {
        uint256 makerAssetFilledAmount; // Total amount of makerAsset(s) filled.
        uint256 takerAssetFilledAmount; // Total amount of takerAsset(s) filled.
        uint256 makerFeePaid; // Total amount of fees paid by maker(s) to feeRecipient(s).
        uint256 takerFeePaid; // Total amount of fees paid by taker to feeRecipients(s).
        uint256 protocolFeePaid; // Total amount of fees paid by taker to the staking contract.
    }

    event LogSwapTest(FillResults);
    event LogSwapTestWithETH(FillResults);

    //   swapTarget: SwapTarget contract address, The `to` field from the API response
    //
    function swapTest(
        bytes calldata swapCallData,
        address payable swapTarget,
        uint256 gasAmount
    ) external returns (FillResults memory fillResults) {
        (bool success, bytes memory data) = swapTarget.call{gas: gasAmount}(
            swapCallData
        );
        require(success, "SWAP_CALL_FAILED");
        fillResults = abi.decode(data, (FillResults));

        emit LogSwapTest(fillResults);
    }

    function swapTestWithoutGas(
        bytes calldata swapCallData,
        address payable swapTarget
    ) external returns (FillResults memory fillResults) {
        (bool success, bytes memory data) = swapTarget.call(swapCallData);
        require(success, "SWAP_CALL_FAILED");
        fillResults = abi.decode(data, (FillResults));

        emit LogSwapTest(fillResults);
    }

    function swapTestWithETH(
        bytes calldata swapCallData,
        address payable swapTarget,
        uint256 gasAmount
    ) external payable returns (FillResults memory fillResults) {
        (bool success, bytes memory data) = swapTarget.call{
            value: msg.value,
            gas: gasAmount
        }(swapCallData);
        require(success, "SWAP_CALL_FAILED");
        fillResults = abi.decode(data, (FillResults));

        emit LogSwapTestWithETH(fillResults);
    }

    receive() external payable {
        emit LogReceived(msg.sender, msg.value);
    }

    fallback() external payable {
        emit LogFallback(msg.sender, msg.value);
    }
}