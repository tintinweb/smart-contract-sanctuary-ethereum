pragma solidity ^0.8.0;

contract Test {
    mapping (uint256 => int256[]) a;
    constructor() {
        a[1].push(1);
        a[1].push(2);
        a[1].push(3);
        a[1].push(4);
        a[1].push(5);
        a[1].push(-6);
        a[1].push(-7);
    }
    function get(uint256 x) external view returns(int256[] memory) {
        return a[x];
    }
}