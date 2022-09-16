/**
 *Submitted for verification at Etherscan.io on 2022-09-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Lottery{

    address public admin;
    uint public amountToBuy;
    bool public isLotteryClosed;
    uint public totalParticipation;
    uint private winingNumber;

    struct ticketDetails{
        address addr;
        bool isFound;
    }
    mapping(address => bool) public userDetail;
    mapping(address => bool) private winner; 
    mapping (uint => ticketDetails) public lotteryNoDetail;

    constructor(address _admin,uint _amountToBuy){
        admin = _admin;
        amountToBuy = _amountToBuy;
    }

    function collectedAmount() public view returns(uint) {
        return address(this).balance;
    }

    modifier checkValidations(uint _ticket){
        require(msg.sender != admin,"admin can't buy ticket");
        require(!isLotteryClosed,"Lottery has been closed");
        require(!userDetail[msg.sender],"User already buy a ticket.");
        require(!lotteryNoDetail[_ticket].isFound,"Ticket no already buy.");
        require(msg.value >= amountToBuy,"Please check your amount and try again latter");
        _;
    }

    function buyTicket(uint _ticket) public payable checkValidations(_ticket){
        ticketDetails memory temp;
        temp.addr=msg.sender;
        temp.isFound=true;
        lotteryNoDetail[_ticket]=temp;
        userDetail[temp.addr]=true;
        totalParticipation++;
    }

    modifier pickNumberValidation(uint _ticket){
        require(msg.sender == admin,"Only access by admin");
        require(lotteryNoDetail[_ticket].isFound == true,"Please add a valid number");
        _;
    }

    function pickNumber(uint _ticket) public pickNumberValidation(_ticket){        
        winingNumber=_ticket;        
        isLotteryClosed=true;
        winner[lotteryNoDetail[_ticket].addr]=true;
    }

    modifier claimAmountValidation(){
        require(winner[msg.sender],"Please try again latter");
        _;
    }

    function claimAmount() public claimAmountValidation {
        payable(msg.sender).transfer(collectedAmount());
        // (bool status, ) = (msg.sender).call{value: collectedAmount()}("");
        // require(status,"ether status");
    }

}