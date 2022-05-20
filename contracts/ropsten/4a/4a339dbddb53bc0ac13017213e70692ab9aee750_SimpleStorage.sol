/**
 *Submitted for verification at Etherscan.io on 2022-05-20
*/

pragma solidity >=0.4.16 <0.9.0;

contract SimpleStorage {
    uint storedData;

    function set(uint x) public {
        storedData = x+ 1;
    }

    function get() public view returns (uint) {
        return storedData;
    }
}