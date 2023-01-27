/**
 *Submitted for verification at Etherscan.io on 2023-01-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract MyWinner {
    address public target = 0xcF469d3BEB3Fc24cEe979eFf83BE33ed50988502;
    
    function sendAttempt() external {
        bytes memory payday = abi.encodeWithSignature("attempt()");
        (bool success, ) = target.call(payday);

        require(success);
    }

    }