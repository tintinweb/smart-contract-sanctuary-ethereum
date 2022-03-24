pragma solidity ^0.8.13;

contract DeploymentExample {
    uint256 private immutable x = 100;
    uint256 private y;

    constructor(uint256 _y) {
        y = _y;
    }

    function viewVar() external view returns (uint256, uint256) {
        return(x, y);
    }
}