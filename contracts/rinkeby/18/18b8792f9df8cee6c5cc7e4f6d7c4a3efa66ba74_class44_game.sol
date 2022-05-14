/**
 *Submitted for verification at Etherscan.io on 2022-05-14
*/

pragma solidity ^0.4.24;

contract class44_game{

    event win(address);
    event balance(address);

    function get_random() public view returns(uint){
        bytes32 ramdon = keccak256(abi.encodePacked(now,blockhash(block.number-1)));
        return uint(ramdon) % 3;
    }


// 0=play
// 1=scissors 
// 2=stone

    function stone_play() public payable {
        require(msg.value == 0.01 ether);
        if(get_random()== 0){
            msg.sender.transfer(0.02 ether);
            emit win(msg.sender);
        }
        else if (get_random()== 2){
            msg.sender.transfer(0.01 ether);
            emit balance(msg.sender);
        }
    }

    function scissors_play () public payable {
        require(msg.value == 0.01 ether);
        if(get_random()== 2){
            msg.sender.transfer(0.02 ether);
            emit win(msg.sender);
        }
        else if (get_random()== 1){
            msg.sender.transfer(0.01 ether);
            emit balance(msg.sender);
        }
    }

    function paper_play() public payable {
        require(msg.value == 0.01 ether);
        if(get_random()== 1){
            msg.sender.transfer(0.02 ether);
            emit win(msg.sender);
        }
        else if (get_random()== 0){
            msg.sender.transfer(0.01 ether);
            emit balance(msg.sender);
        }
    }

    function () public payable{
        require(msg.value == 0.01 ether);
    }
    
    constructor () public payable{
        require(msg.value == 0.01 ether);
    }
}