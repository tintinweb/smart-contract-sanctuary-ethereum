/**
 *Submitted for verification at Etherscan.io on 2022-04-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;


contract BuyOpenSeaV2 {

    address private _proxy = 0x7f268357A8c2552623316e2562D90e642bB538E5;

    function batchBuyWithETH(
        uint256 payment, bytes memory orderDetail
    ) payable external {
        // execute trades
        _trade(payment, orderDetail);

        // return remaining ETH (if any)
        assembly {
            if gt(selfbalance(), 0) {
                let callStatus := call(
                    gas(),
                    caller(),
                    selfbalance(),
                    0,
                    0,
                    0,
                    0
                )
            }
        }
    }

    function _trade(
        uint256 payment, bytes memory orderDetail
    ) internal {

        _proxy.call{value: payment}(orderDetail);

    }
}