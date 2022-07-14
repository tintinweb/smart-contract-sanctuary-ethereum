/**
 *Submitted for verification at Etherscan.io on 2022-07-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract TimeWindow {

/*
In theory "start" is the only weakpoint within this contract
if someone can view start they will be able to copy the code 
and check when their sale is available.
*/
uint private start = 10;
uint private day = 86400;


    /* How much time has passed since the birth of contract */
    function elapsed() private view returns(uint){
        uint _now = block.timestamp;
        return _now - start;
    }


    /* The current time left within the day */   
    function currentDay() public view returns(uint){
        uint _now = block.timestamp;
        uint Passed = elapsed() / day;
        uint past = Passed * day;
        uint todaysTime = _now - past;
        
        return todaysTime;
    }


    /* Determines a new time period everyday. params(days, item)
    depending on how many days you wish to set you can replace "day"
    with 2days or 3days */
    function timeWindow(uint _days, uint _itemID) public view returns(uint[2] memory){
        uint _day = (_days * day);
        address miner = msg.sender;
        uint magicNumbr = 1657080829;

        uint result = uint(keccak256(abi.encodePacked(miner, magicNumbr, _itemID))) % _day;
        uint r = (day - result);
        if(r < 1500){
        uint n = (1500 - r);   
        result -= n; 
        }
        
        return [result, result + 1500];
    }


    /* */
    function miningPeriod() private view returns(bool){
        uint _current = currentDay();
        uint[2] memory _window = timeWindow(1,1);
        bool _allow = (_current > _window[0] && _current < _window[0]);
        
        return _allow;
    }


    function status() public view returns(string memory){
        string memory message;
        uint c = currentDay();
        uint[2] memory _window = timeWindow(1,1);

        if(c < _window[0]){message = "Stand By";}
        else if(miningPeriod() == true){message = "Mint Now!";}
        else if(c > _window[1]){message = "Too Late!";}
        return message;
    }


    mapping(address => purch) _purchases;
    purch[] public all;


    struct purch{
        address who;
        uint256 value;
        string status;
    }


    function makePurchase()public payable{
        uint256 price = 2500000000000000;
        string memory stats = "Full Price";
        uint payment = msg.value;
        if(miningPeriod()==true){
        price = 99000000000000;
        stats = "discounted";
        }
        
        require(payment >= price, "value not met");
        _purchases[msg.sender] = purch(msg.sender,payment,stats);
    }


    function viewPayment()public view returns(purch memory){
        return _purchases[msg.sender];
    }


    address owns = msg.sender;

    function withdraw() public payable{
    require(msg.sender == owns, "not owner");
    require(payable(0x484C73961d903c00A7fb218abdE0310D510ACa7A).send(address(this).balance)); //Shadawi Official Address
    }

    



    

}