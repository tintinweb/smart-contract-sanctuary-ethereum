pragma solidity ^0.8.9;

contract Errors { 

    error CustomError(string message, uint256 amount);

    function test() external {
        revert CustomError('test', 1000);
    }
}