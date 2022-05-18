/**
 *Submitted for verification at Etherscan.io on 2022-05-18
*/

pragma solidity ^0.4.0;
contract SimpleStorage {
    uint storedData;
    function set(uint x) public {
        storedData = x;
    }
    function get() public constant returns (uint) {
        return storedData;
    }
}