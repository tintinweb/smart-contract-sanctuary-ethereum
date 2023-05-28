/**
 *Submitted for verification at Etherscan.io on 2023-05-28
*/

pragma solidity >=0.7.0 <0.9.0;

/** 
 * @title Ballot
 * @dev Implements voting process along with vote delegation
 */
contract ErrorV4 {
    error Debug(uint);

    // 0xc2985578
    function foo() external {
        revert Debug(0);
    }

    // 
    // 0x274cdd5c
    function goo() external  {
        revert Debug(1);
    }

    function hoo() external {
        revert("");
    }
}