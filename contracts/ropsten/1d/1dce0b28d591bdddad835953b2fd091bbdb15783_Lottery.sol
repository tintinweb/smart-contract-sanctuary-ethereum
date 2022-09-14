/**
 *Submitted for verification at Etherscan.io on 2022-09-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract Lottery {

    receive() external payable{}
    
    address public owner;
    uint private  winningNumber;

    uint private totalSupplyInEth;
    struct details {
        uint lotteryNumber;
        uint ethVal;
        uint256 timeStamp;
    }
   
// address(this).balance; check total balance of contract

    mapping (uint => bool) private  records; // uint =. lottery number, bool => is used or not
    mapping (address => details) private userDetails;

    constructor(address _admin){
        owner = _admin;
    }

    modifier checkEthVal(uint _amount){
        require(msg.value>=_amount, "Provide valid amount");
        _; // like continue 
    }

    // check only owner can do this
    modifier checkOwner(){
        require(msg.sender==owner,"Only owner has access");
        _;
    }


    function buyTicket(uint _lotteryNumber) external payable  checkEthVal(10000) {
        require(records[_lotteryNumber]==false,"lottery number is already registred");
        require(userDetails[msg.sender].lotteryNumber<=0,"user already registered");
        details memory temp1;
        temp1.ethVal = msg.value;
        temp1.timeStamp = block.timestamp;
        temp1.lotteryNumber = _lotteryNumber;
        userDetails[msg.sender] = temp1;
        
        records[_lotteryNumber] = true;
    }



    function winningNum(uint _winNum) external checkOwner {
        require(_winNum>0," please provide value greater then 0");
        winningNumber = _winNum;
    }

    /**
        user can claim reward
    */
     function claimReward() public{
        require(winningNumber>0," till now winning no is not decided");
        
        require(userDetails[msg.sender].ethVal>0,"you cannot withdraw");

        require(userDetails[msg.sender].lotteryNumber == winningNumber,"you are not lucky winner");
        
        
        // check user is lottery no is matched with the user defind no.

        (bool status, )= (msg.sender).call{value:address(this).balance}("");
        require(status,"eth not sent");
        
    }



    function checkUserBal() external view returns (details memory){
        return  userDetails[msg.sender];
    }

    function checkWinningAmount() public view checkOwner returns (uint){
        return address(this).balance;
    }
 }