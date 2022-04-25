/**
 *Submitted for verification at Etherscan.io on 2022-04-25
*/

// SPDX-License-Identifier: MIT
// File: contracts/CrackingGovernance.sol


pragma solidity >=0.8.0 <=0.9.0;

contract CrackingGovernance {
    uint256 private creationTimestamp;
    string private msgToCaller;

    constructor() {
        creationTimestamp = block.timestamp;
        msgToCaller = "DERJY ROYAL";
    }

    function getRoyalties(uint256 minutesSince)
        public
        view
        returns (string memory heh)
    {
        assert(block.timestamp > creationTimestamp + minutesSince * 1 minutes);
        heh = msgToCaller;
        return heh;
    }
}