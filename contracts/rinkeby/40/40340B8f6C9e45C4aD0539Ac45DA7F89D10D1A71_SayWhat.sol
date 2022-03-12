// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

/// @author dantop114
/// @notice A simple contract.
contract SayWhat {
    /// @notice what
    string private what;

    /// @dev Constructor, called when the contract is deployed.
    /// @param what_ The initial what.
    constructor(string memory what_) {
        what = what_;
    }

    /// @notice The main function. This contract can say 
    function say() external view returns(string memory) { // -> keccak("say()")
        return what;
    }

    /// @notice Anyone can make this contract say anything.
    /// @param what_ The new what.
    function setWhat(string memory what_) external { // -> keccak("setWhat(string)")[:4] = 0x61e6ff16
        what = what_;
    }
}