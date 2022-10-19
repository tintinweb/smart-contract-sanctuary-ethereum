/**
 *Submitted for verification at Etherscan.io on 2022-10-19
*/

// File: contracts/lottery.sol


pragma solidity >=0.7.0 <0.9.0;

contract Lottery {
     address public manager;
     address payable[] public participants;

     constructor() {
        manager = msg.sender; //global ,,who depoly the contract
     }

    receive() external payable{
        require(msg.value==0.01 ether,"please send exact price");
        
        participants.push(payable(msg.sender));
    }

    function getBalance() public view returns(uint){
        require(msg.sender == manager);
        return address(this).balance;
    }

    function random() public view returns(uint) {
        // keccak256(abi.encodePacked())
        // return participants.length;
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp,participants.length)));
    }

    function select() public  {
        require(msg.sender==manager);
        require(participants.length>=3);
        uint r=random();
        address payable winner;
        uint index = r % participants.length;
        winner = participants[index];
        // return winner;
        winner.transfer(getBalance());

        participants = new address payable[](0);
    }
}