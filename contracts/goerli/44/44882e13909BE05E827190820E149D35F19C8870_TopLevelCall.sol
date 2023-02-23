/**
 *Submitted for verification at Etherscan.io on 2023-02-22
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract AlwaysRevert {
    fallback() external {
        revert();
    }
}

contract TopLevelCall {
    AlwaysRevert faulty;
    bool _shouldChange;

    constructor() {
        faulty = new AlwaysRevert();
    }

    function exec() public returns (bytes memory) {
        (, bytes memory data) = address(faulty).delegatecall("");
        // Explicitly not check succcess to make top level call succesful
        
        _shouldChange = !_shouldChange; // Always toggle so a diff is shown in traces
        
        return data;
    }
}