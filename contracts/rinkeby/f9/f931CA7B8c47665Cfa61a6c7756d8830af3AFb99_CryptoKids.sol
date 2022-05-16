/**
 *Submitted for verification at Etherscan.io on 2022-05-16
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.7;

contract CryptoKids {
    // owner DAD
    address owner;
    event logKidFundReceived(address addr, uint amount, uint contractBalance);
    constructor(){
        owner = msg.sender;
    }
        //define Kid
    struct Kid {
        address payable walletAddress;
        string firstName;
        string lastName;
        uint releaseTime;
        uint amount;
        bool canWithdraw;
    }
    Kid[] public kids;
     
    modifier onlyOwner(){
        require(msg.sender == owner,"Only owner can add kids");
        _;
    } 
    //add kid to contract

    function addKid( address payable _walletAddress,   string memory _firstName,  string memory _lastName, uint _releaseTime,  uint _amount,  bool _canWithdraw) public onlyOwner {
        kids.push(Kid(
            _walletAddress,
            _firstName,
            _lastName,
            _releaseTime,
            _amount,
            _canWithdraw
        ));
    } 
    //deposit funds to contract, specifically to a kid's account

    function deposit(address _walletAddress) payable public {
         addToKidsBalance(_walletAddress);
    }

    function balanceOf() public view returns(uint) {
        return address(this).balance;
    }
    
    function addToKidsBalance(address _walletAddress) private  {
        for (uint i = 0; i < kids.length; i++) {
            if(kids[i].walletAddress == _walletAddress) {
                kids[i].amount += msg.value;
                emit logKidFundReceived(_walletAddress, msg.value, balanceOf());
            }
        }
    }

    function getIndex(address _walletAddress) view private returns(uint) {
        for(uint i = 0; i < kids.length; i++) {
            if(kids[i].walletAddress == _walletAddress) {
                return i;
            }
        }
        return 999;
    }
    // kit checks if able to withdraw

    function availableToWithdraw(address _walletAddress) public returns(bool) {
        uint i = getIndex(_walletAddress);
        require(block.timestamp > kids[i].releaseTime, "You cannot withdraw yet");
        if(block.timestamp > kids[i].releaseTime) {
            kids[i].canWithdraw = true;
            return true;
        } else {
            return false;
        }
        
    }

    //withdraw money
    function withdraw(address payable _walletAddress) payable public {
        uint i = getIndex(_walletAddress);
        require(msg.sender == kids[i].walletAddress , "You must be the kid to withdraw");
        require(kids[i].canWithdraw == true, "You are not able to widthdraw at this time");
        kids[i].walletAddress.transfer(kids[i].amount);
    }
}