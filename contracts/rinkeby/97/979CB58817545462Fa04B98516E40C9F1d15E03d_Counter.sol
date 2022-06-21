/**
 *Submitted for verification at Etherscan.io on 2022-06-21
*/

pragma solidity >=0.7.0 <0.9.0;

contract Counter {
    uint public count = 0;
    
    function increment() public returns(uint) {
        count += 1;
        return count;
    }

    function addInteger2(uint intToAdd) public returns(uint) {
        count += intToAdd;
        return count;
    }

    function reset() public returns(uint) {
        count = 0;
        return count;
    }
}