/**
 *Submitted for verification at Etherscan.io on 2022-08-05
*/

pragma solidity ^0.8.0;

contract transendTest{
    function getSenderInfo() public view returns(address){
        return msg.sender;
    }

    function block_coinbase() public view returns(address){
        return block.coinbase;
    }

}