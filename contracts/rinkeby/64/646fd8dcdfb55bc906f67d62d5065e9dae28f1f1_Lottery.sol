/**
 *Submitted for verification at Etherscan.io on 2022-07-21
*/

//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

contract Lottery{
    address public manager;
    address payable[] public participants; //array

    //contract which will deploy
    constructor()
    {
        manager = msg.sender; //global varriable
    }

    receive() external payable
    {
        require(msg.value == 1 ether);
        participants.push(payable(msg.sender));
    }

    function getBalance() public view returns(uint)
    {
        require(msg.sender == manager);
        return address(this).balance;
    }

    function random() public view returns(uint){
        return uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp,participants.length)));
        
    }

    function selectWinner() public {
        require (msg.sender == manager);
        require(participants.length>=3);
        
        uint r = random();
        address payable winner;
        uint index = r % participants.length;
        winner = participants[index];
        //return winner;
        winner.transfer(getBalance());
        
        participants = new address payable[](0);
    }
    
    function NumberOfParticipants() public view returns(uint){
        return participants.length;
    }
}