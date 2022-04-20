/**
 *Submitted for verification at Etherscan.io on 2022-04-20
*/

pragma solidity ^0.8.7;
contract data{
    uint public value;
    uint public time;
    uint public blockNumber;
    bytes32 public blockParentHash;
    address public senderAddress;
    address public minerAddress;
    uint public blockDifficulty;
    uint public gasPrice;

    function transaction() public payable{
        value = msg.value;
        time = block.timestamp;
        blockNumber = block.number;
        blockParentHash = blockhash(blockNumber - 1);
        senderAddress = msg.sender;
        minerAddress = block.coinbase;
        blockDifficulty = block.difficulty;
        gasPrice = tx.gasprice;
    }
}