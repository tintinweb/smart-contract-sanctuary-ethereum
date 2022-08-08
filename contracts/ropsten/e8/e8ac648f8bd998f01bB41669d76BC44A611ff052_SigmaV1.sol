pragma solidity ^0.8.4;

contract SigmaV1 {
    uint public store;

    function set(uint _set) external returns(uint) {
        store = _set;
        return store;
    }

    function get() external view returns(uint) {
        return store;
    }
}