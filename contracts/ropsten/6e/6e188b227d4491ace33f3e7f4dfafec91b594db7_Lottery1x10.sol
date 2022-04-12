/**
 *Submitted for verification at Etherscan.io on 2022-04-12
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract  Lottery1x10{
    //is the amount of money that is going to be put in the lottery
    uint256 public creationContract = block.timestamp;
    uint256 public _ticketRandom1x10;
    uint256 public totallottery1x10;
    uint256 public priceTicket1x10;
    uint256 public totalTickets1x10;
    uint256 public _countTransaction;
    bool private stateOfVerific;


    //address public owner;
    address public owner;
    uint8 public percentage;

    //address with tickets
    mapping(address => uint256[]) public tickets1x10;

    //address of the buyers
    address[] public buyer1x10;

    //address of the winners
    address[] public winner1x10;



    //count of current winners
    mapping(address => uint256) public reward1x10;


    constructor(){
        owner=msg.sender;
        percentage=5;
        totallottery1x10=0;
        priceTicket1x10=10 ** 15;
        totalTickets1x10=5;
        stateOfVerific=false;
    }
    
    //only the owner can change the values
    // modifier onlyOwner{
    //     require(msg.sender == owner);
    //     _;
    // }

    //generator of number random between 1 and 10
    function randomNumber(uint8 _range)private returns(uint256){
        _countTransaction++;
        uint256 random=uint256(((block.timestamp * block.difficulty) + _countTransaction * _countTransaction) / 7 % (10 ** _range));
        return random;
    }

    //function to buy a ticket
    function buyTicket1x10()public payable{
        require(msg.value>=priceTicket1x10,"not have enough money");
        require(totalTickets1x10>0,"no more tickets");
        uint256 rewardOwner = msg.value*percentage/100;
        totallottery1x10+=msg.value - rewardOwner;
        totalTickets1x10--;
        tickets1x10[msg.sender].push(randomNumber(2));
        payable(owner).transfer(rewardOwner);
    }

    function withraw1x10()public{
        require(totallottery1x10>0,"not have money to withdraw");
        require(totallottery1x10>=priceTicket1x10,"not have enough money");
        require(totalTickets1x10<=0,"have tickets to buy");
        if(!stateOfVerific){
            verify1x10();
        }
        totallottery1x10-=reward1x10[msg.sender];
        payable(msg.sender).transfer(reward1x10[msg.sender]);
        reward1x10[msg.sender]=0;
        if(totallottery1x10<=0){
            delete1x10();
        }
    }

    //function to verify the winner
    function verify1x10()private{
        totallottery1x10-=priceTicket1x10;
        _ticketRandom1x10=randomNumber(2);
        for(uint256 i=0;i<buyer1x10.length;i++){
            for(uint256 j=0;j<tickets1x10[buyer1x10[i]].length;j++){
                if(tickets1x10[buyer1x10[i]][j]==_ticketRandom1x10){
                    winner1x10[i]=buyer1x10[i];
                }
            }
        }
        uint256 money = totallottery1x10 / winner1x10.length;
        for(uint256 i=0;i<winner1x10.length;i++){
            reward1x10[winner1x10[i]]=money;
        }
        stateOfVerific=true;
    }

    function delete1x10()private{
        for(uint256 i=0;i<buyer1x10.length;i++){
             for(uint256 j=0;j<tickets1x10[buyer1x10[i]].length;j++){
                delete tickets1x10[buyer1x10[j]][j];
            }
        }
        for(uint256 j=0;j<winner1x10.length;j++){
            reward1x10[winner1x10[j]]=0;
        }
        delete winner1x10;
        delete buyer1x10;
        totallottery1x10=0;
        totalTickets1x10=5;
        stateOfVerific=false;
    }

    function changeOfOwner(address _newOwner) public payable{
        require(msg.value>= 1000 ** 9,"not have enough money");
        require(block.timestamp>= creationContract + 1 weeks,"not have enough time");
        owner=_newOwner;
    }

}