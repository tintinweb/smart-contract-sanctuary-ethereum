pragma solidity ^0.8.11;
contract Counter {
    uint public count = 0;

    function incrementCount() public {
        count ++;
    }
}