/**
 *Submitted for verification at Etherscan.io on 2022-08-29
*/

pragma solidity ^0.8.0;

contract SpokePool {

    address private token = 0xE09eE65b3A59900401f9148DBA820aEDa8d6D326;
    address private token2 = 0x0089Ed33ED517F58a064D0ef56C9E89Dc01EE9A2;

    event FilledRelay(uint256 amount,uint256 totalFilledAmount,uint256 fillAmount,uint256 repaymentChainId,uint256 originChainId,uint256 destinationChainId,uint64 relayerFeePct,uint64 appliedRelayerFeePct,uint64 realizedLpFeePct,uint32 depositId,address destinationToken,address indexed relayer,address indexed depositor,address recipient,bool isSlowRelay);
    event SetDepositQuoteTimeBuffer(uint32 newBuffer);

    function oneFinding() external{
        emit FilledRelay(1000000, 1000000, 1000000, 111, 222, 333, 123, 456, 678, 1, token, address(0x6453), address(0x5467), address(0x2234), false);
    }

    function twoFindings() external {
        emit FilledRelay(1000000, 1000000, 1000000, 111, 222, 333, 123, 456, 678, 1, token, address(0x6453), address(0x5467), address(0x2234), false);
        emit FilledRelay(9898999, 9898999, 9898999, 111, 222, 333, 123, 456, 678, 1, token2, address(0x4432), address(0x7632), address(0x8819), true);

    }

    function oneFindingOneWrongEvent() external {
        emit FilledRelay(9898999, 9898999, 9898999, 111, 222, 333, 123, 456, 678, 1, token2, address(0x4432), address(0x7632), address(0x8819), true);
        emit SetDepositQuoteTimeBuffer(222);
    }

}