/**
 *Submitted for verification at Etherscan.io on 2022-08-03
*/

// File: contracts/Lottery.sol


//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.0 <0.9.0;
contract Lottery {
    address public manager;
    address payable[] public participants ;
    address payable public winner;
    constructor(){
        manager= msg.sender ;
    }

    receive() external payable{
        require( msg.value== 2 ether);
        participants.push(payable(msg.sender));
     }

function getBalance() public view returns(uint){
    require(msg.sender == manager);
    return address(this).balance ;
}

function random() public view returns(uint){
    return uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp,participants.length)));
}



function selectWinner() public payable{
    require(msg.sender==manager);
    require(participants.length>=3);
    uint r=random();
    uint index= r%participants.length;
    winner=participants[index];
    winner.transfer(getBalance());
}

function getWinner() public view returns(address){
    address Winner = winner;
    return Winner;
}
        
}