pragma solidity ^0.8.4;

contract Test {
    function test() external view returns (address) {
        return msg.sender;
    }
}