pragma solidity ^0.8.4;

contract SigmaV2 {
    uint public store;

    function get() external view returns(uint) {
        return store;
    }

    function increment() external returns(uint) {
        store += 10;
        return store;
    }
}