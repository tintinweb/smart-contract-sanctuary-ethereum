/**
 *Submitted for verification at Etherscan.io on 2023-01-21
*/

// File: lottery.sol



pragma solidity ^0.8.12;



contract Lottery {

    mapping (address => uint256) participants;

    uint256 total_participants;

    uint256 winning_number;

    uint256 winning_money;

    address owner;



    constructor() {

        owner = msg.sender;

    }



    function getOwner() public view returns (address) {

        return owner;

    }



    function lottery_in(uint256 number) public payable {

        if (msg.value == 0.01 ether) {

            participants[msg.sender] = number;

            total_participants = total_participants + 1;



        } else {

            revert();

        }

    }



    function lottery_set(uint256 number) public {

        require(msg.sender == owner);

        winning_number = number;

        winning_money = address(this).balance / total_participants;

    }



    function lottery_claim() public {

        if (participants[msg.sender] == winning_number) {

            address payable to = payable(msg.sender);

            to.transfer(winning_money); //transfer ethereum



            participants[msg.sender] = winning_money + 1; //reset winner

        } else {

            revert();

        }



    }

}