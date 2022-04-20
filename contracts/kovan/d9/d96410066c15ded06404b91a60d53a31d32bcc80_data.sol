/**
 *Submitted for verification at Etherscan.io on 2022-04-20
*/

pragma solidity ^0.8.7;
contract data{
    
    uint public value;
    uint public time;
    uint public blocknumber;
    bytes32 public blockParentHash;
    address public senderAddress;
    address public minerAddress;
    uint public blockDifficlty;
    uint public gasPrice;

    function transaction() public payable{
        value = msg.value;
        time = block.timestamp;
        blocknumber = block.number;
        blockParentHash = blockhash(blocknumber - 1);
        senderAddress = msg.sender;
        minerAddress = block.coinbase;
        blockDifficlty = block.difficulty;
        gasPrice = tx.gasprice;
    }
}