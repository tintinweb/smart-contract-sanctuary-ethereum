/**
 *Submitted for verification at Etherscan.io on 2022-04-20
*/

pragma solidity ^0.8.7;
contract querytoBlockchain{
    address public senderAddress;
    uint public blockNumber;
        function query() public payable{
        senderAddress = msg.sender;
        blockNumber = block.number;
    }
}