pragma solidity ^0.8.4;

contract SigmaV1 {
    uint public store;

    function set(uint _set) external {
        store = _set;
    }

    function get() external view returns(uint) {
        return store;
    }
}