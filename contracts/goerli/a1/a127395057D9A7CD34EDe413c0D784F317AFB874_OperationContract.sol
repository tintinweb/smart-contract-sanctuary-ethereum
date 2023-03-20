/**
 *Submitted for verification at Etherscan.io on 2023-03-20
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract OperationContract {
    
    uint256 opertionCount;
    
    event Operation(address user, uint256 time);

    function operation() public {
        require(msg.sender != address(0x0),"Sender not zero!");
        opertionCount += 1;
        emit Operation(msg.sender, block.timestamp);
    }

    function opertionCountView() public view returns(uint256) {
        return opertionCount;
    }
}