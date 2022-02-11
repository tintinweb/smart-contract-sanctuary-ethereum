/**
 *Submitted for verification at Etherscan.io on 2022-02-11
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.9;

contract timeFeed {



    uint256 public timeStamp;

    function setTimeStamp(uint256 _newTime) public{
        require (msg.sender == 0x8A146c65FA4355381BF0c69182a7DbccDc9B0CbB,'Only me');
        timeStamp = _newTime;
    }

}