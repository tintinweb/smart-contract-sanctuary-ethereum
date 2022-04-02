/**
 *Submitted for verification at Etherscan.io on 2022-04-01
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;



// File: TestTenderly.sol

contract TestTenderly {
    function testNoError() external pure {}
    
    function testError() external pure {
        revert('Fail');
    }
}