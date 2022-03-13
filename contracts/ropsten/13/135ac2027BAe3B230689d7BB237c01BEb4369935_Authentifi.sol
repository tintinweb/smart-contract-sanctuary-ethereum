/**
 *Submitted for verification at Etherscan.io on 2022-03-13
*/

// File: Authentifi.sol

pragma solidity >=0.4.0 <0.7.0;
contract Authentifi {
    uint storedData;
    function set(uint x) public {
        storedData = x;
    }
    function get() public view returns (uint) {
        return storedData;
    }
}