/**
 *Submitted for verification at Etherscan.io on 2023-01-28
*/

pragma solidity ^0.8.17;

contract Beet {
    event Woof(uint256 blockNumber, bytes32 blockHash, bytes32 blockHash_1, uint256 difficulty);

    function yo() payable external {
        emit Woof(block.number, blockhash(block.number), blockhash(block.number - 1), block.difficulty);
    }
}