/**
 *Submitted for verification at Etherscan.io on 2022-08-30
*/

//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

contract TestHubPool{
    event FilledRelay(uint256 amount, uint256 totalFilledAmount, uint256 fillAmount, uint256 repaymentChainId, uint256 originChainId, uint256 destinationChainId, uint64 relayerFeePct, uint64 appliedRelayerFeePct, uint64 realizedLpFeePct, uint32 depositId, address destinationToken, address indexed relayer, address indexed depositor, address recipient, bool isSlowRelay);

    function emitEvent(address _depositor) public
    {
        uint16 a = 1;
        address x = 0x1Abf3a6C41035C1d2A3c74ec22405B54450f5e13;
        emit FilledRelay(
            a,
            a,
            a,
            a,
            a,
            a,
            a,
            a,
            a,
            a,
            x,
            x,
            _depositor,
            x,
            true
        );
    }
}