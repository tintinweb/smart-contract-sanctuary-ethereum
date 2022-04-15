// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.12;

import {IStargateRouter} from "./interfaces/IStargateRouter.sol";

/// @notice Contract to swap USDC cross chain using stargate
contract CrossSwap {
    function swapUSDC(
        address _routerAddress,
        uint16 _dstChainId,
        uint _srcPoolId,
        uint _dstPoolId,
        uint _bridgeAmount,
        uint _amountOutMinSg,
        address _destinationAddress
        ) external payable {

        require(msg.value > 0, "must send non-zero amount of gas");
        require(_bridgeAmount > 0, "must swap non-zero amount");

        // Stargate's Router.swap() function sends the tokens to the destination chain.
        IStargateRouter(_routerAddress).swap{value:msg.value}(
            _dstChainId,                                    // the destination chain id
            _srcPoolId,                                     // the source Stargate poolId
            _dstPoolId,                                     // the destination Stargate poolId
            payable(msg.sender),                            // refund adddress. if msg.sender pays too much gas, return extra eth
            _bridgeAmount,                                  // total tokens to send to destination chain
            _amountOutMinSg,                                // minimum
            IStargateRouter.lzTxObj(500000, 0, "0x"),            // 500,000 for the sgReceive()
            abi.encodePacked(_destinationAddress),          // destination address, the sgReceive() implementer
            bytes("")                                       // bytes payload
        );
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.12;
pragma abicoder v2;

interface IStargateRouter {
    struct lzTxObj {
        uint256 dstGasForCall;
        uint256 dstNativeAmount;
        bytes dstNativeAddr;
    }

    function addLiquidity(
        uint256 _poolId,
        uint256 _amountLD,
        address _to
    ) external;

    function swap(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLD,
        uint256 _minAmountLD,
        lzTxObj memory _lzTxParams,
        bytes calldata _to,
        bytes calldata _payload
    ) external payable;

    function redeemRemote(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        uint256 _minAmountLD,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable;

    function instantRedeemLocal(
        uint16 _srcPoolId,
        uint256 _amountLP,
        address _to
    ) external returns (uint256);

    function redeemLocal(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable;

    function sendCredits(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress
    ) external payable;

    function quoteLayerZeroFee(
        uint16 _dstChainId,
        uint8 _functionType,
        bytes calldata _toAddress,
        bytes calldata _transferAndCallPayload,
        lzTxObj memory _lzTxParams
    ) external view returns (uint256, uint256);
}