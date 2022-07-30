/**
 *Submitted for verification at Etherscan.io on 2022-07-29
*/

// File: sisytest.sol


pragma solidity >=0.4.16 <0.9.0;

contract sisytest {
    uint storedData = 1;

    function get() public view returns (uint) {
        return storedData;
    }
}