/**
 *Submitted for verification at Etherscan.io on 2022-11-21
*/

pragma solidity ^0.8.0;

interface IOutbox {
    function l2ToL1Sender() external view returns (address);
}

contract Test {
    event Echo(address caller, address l2Caller, bytes data);
    fallback() external {
        emit Echo(
            msg.sender,
            IOutbox(address(0x45Af9Ed1D03703e480CE7d328fB684bb67DA5049)).l2ToL1Sender(),
            msg.data
        );
    }
}