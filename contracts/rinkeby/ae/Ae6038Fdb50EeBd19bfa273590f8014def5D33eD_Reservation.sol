/**
 *Submitted for verification at Etherscan.io on 2022-06-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
pragma abicoder v2;

contract Reservation
{
    uint[] public seat;

    struct Passenger
    {
        string name;
        bool registered;
        uint purchasedTicket;
    }

    struct Train
    {
        string name;
        uint TotalTicket;
        uint SoldTCount;
        uint RemTCount;
    }


    address public RailwayAuthority;

    //address public StationMaster;
    //address public 

    Train[] public trains;

    mapping(address => Passenger) public passengers;

    //add train name
    constructor(string[] memory _name)
    {
        RailwayAuthority = msg.sender;
        for (uint i = 0; i < _name.length; i++)
        {
            trains.push(Train({name: _name[i], TotalTicket: 10, SoldTCount: 0, RemTCount: 0}));
        }
    }

    function createAcc(address _passengers, string memory _name) public 
    {
        require(msg.sender == RailwayAuthority , "Only authority can give right to create account.");
        require(!passengers[_passengers].registered,"The passenger already registered.");
        require(passengers[_passengers].purchasedTicket == 0);
        passengers[_passengers].registered = true;

        passengers[_passengers].name = _name;
        passengers[_passengers].purchasedTicket = 0;
        //pCount += 1;

        //pAddList[pCount] = _passengers;
        //pAddList.push(_passengers);
    }

    uint BT = 0;
    uint _RemTCount = 0;
    //uint TotalTicket = trains[trainIndex].TotalTicket;
    function bookSeats(uint trainIndex, uint _buyTicket) public
    {
        Passenger storage sender = passengers[msg.sender];
        require(sender.registered, "Registered User");
        require(sender.purchasedTicket <= 3, "Eligible for purchase.");


        if(sender.purchasedTicket == 0)
        {
            if(trains[trainIndex].TotalTicket > _RemTCount && _RemTCount > 0)
            {
                trains[trainIndex].SoldTCount = _buyTicket + BT;
                BT = trains[trainIndex].SoldTCount;
                _RemTCount = _RemTCount - _buyTicket;
                trains[trainIndex].RemTCount = _RemTCount;
                sender.purchasedTicket += _buyTicket;
            }
            else
            {
                trains[trainIndex].SoldTCount = _buyTicket + BT;
                BT = _buyTicket;
                _RemTCount = trains[trainIndex].TotalTicket - _buyTicket;
                trains[trainIndex].RemTCount = _RemTCount;
                sender.purchasedTicket += _buyTicket;
            }
             
        }
        else if(sender.purchasedTicket <= 3)
        {
            if(_buyTicket <= _RemTCount)
            {
                trains[trainIndex].SoldTCount = _buyTicket + BT;
                BT = trains[trainIndex].SoldTCount;
                _RemTCount = _RemTCount - _buyTicket;
                trains[trainIndex].RemTCount = _RemTCount;
                sender.purchasedTicket += _buyTicket;
            }
        }

         seat.push(_RemTCount);
         seat.push(trains[trainIndex].SoldTCount);
    }

    function PassengerCheck(address _passengers) public view returns(string memory name_, uint _purchasedTicket)
    {
        name_ = passengers[_passengers].name;
        _purchasedTicket = passengers[_passengers].purchasedTicket;
    }

}