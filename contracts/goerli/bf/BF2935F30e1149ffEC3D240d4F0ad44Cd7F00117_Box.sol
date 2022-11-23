pragma solidity 0.8.7;

contract Box {
    uint256 public v;

    function initialize(uint256 _v) external {
        v = _v;
    }
}