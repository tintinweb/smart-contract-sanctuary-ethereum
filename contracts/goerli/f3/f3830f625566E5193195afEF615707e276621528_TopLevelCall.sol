/**
 *Submitted for verification at Etherscan.io on 2023-02-23
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract TopLevelCall {
    bool public _shouldChange;
    bool public _shouldNotChange;

    function exec() public returns (bytes memory) {
        (, bytes memory data) = address(this).delegatecall(
            abi.encode(TopLevelCall.alwaysRevert.selector)
        ); // Change execution context

        // Explicitly not check succcess to make top level call succesful

        _shouldChange = !_shouldChange; // Always toggle so a diff is shown in traces

        return data;
    }

    function alwaysRevert() external {
        _shouldNotChange = !_shouldNotChange;
        revert();
    }
}