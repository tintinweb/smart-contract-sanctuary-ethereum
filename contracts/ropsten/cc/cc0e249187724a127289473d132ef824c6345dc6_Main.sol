/**
 *Submitted for verification at Etherscan.io on 2022-04-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0 ;

contract Main {

    event showDetails(address currentAddress , uint addressBalance , uint currentTime);

    function call() public {
        emit showDetails(msg.sender , (msg.sender).balance , block.timestamp);
    }

}