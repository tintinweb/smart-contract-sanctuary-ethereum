/**
 *Submitted for verification at Etherscan.io on 2022-10-01
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

contract MyContract {

    uint256 public number;
    uint public timestamp ;
    address public myAddress;

    function setName(uint _number) public {
        number = _number;
        timestamp = block.timestamp;
        myAddress = msg.sender;
    }

}