/**
 *Submitted for verification at Etherscan.io on 2022-06-25
*/

pragma solidity >=0.6.6;

contract Test {
    function Time_callv() public view returns (uint256) {
        return block.timestamp;
    }

    function Time_call() public view returns (uint256) {
        return block.number;
    }
}