pragma solidity ^0.8.12;

contract Dummy {
    error DummyError(uint256 time, uint256 abc);

    function reverted() external view {
        revert DummyError(block.timestamp, 1023);
    }

    function notReverted() external pure returns (uint256){
        return 123;
    }
}