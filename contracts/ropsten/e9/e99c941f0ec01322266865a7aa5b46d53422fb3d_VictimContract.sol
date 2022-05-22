/**
 *Submitted for verification at Etherscan.io on 2022-05-22
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.4.23;

contract VictimContract {
    
    string public name;

    constructor () public {
        name = 'VictimContract';
    }

    /* Fallback function, don't accept any ETH */
    function() public payable {
        revert("Contract6Delegatee1 does not accept payments");
    }

}