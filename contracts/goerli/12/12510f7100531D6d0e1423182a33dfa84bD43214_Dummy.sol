pragma solidity ^0.8.12;

contract Dummy {
    error DummyError(uint256 time, uint256 abc);
    uint256 n;

    function reverted(uint256 a) external {
        revert DummyError(block.timestamp, 1023);
	n = a;
    }

    function notReverted() external pure returns (uint256){
        return 123;
    }
}