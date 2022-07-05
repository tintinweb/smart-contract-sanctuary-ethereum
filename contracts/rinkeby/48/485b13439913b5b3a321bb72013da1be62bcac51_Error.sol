/**
 *Submitted for verification at Etherscan.io on 2022-07-05
*/

// File: contracts/SimpleStorage.sol


pragma solidity ^0.8;

contract Error {
    function testRequire(uint _i) public pure {
        // Require should be used to validate conditions such as:
        // - inputs
        // - conditions before execution
        // - return values from calls to other functions
        require(_i > 10, "Input must be greater than 10");
    }
}