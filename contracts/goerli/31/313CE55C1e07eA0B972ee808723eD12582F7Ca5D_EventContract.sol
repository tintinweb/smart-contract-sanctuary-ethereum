//SPDX-License-Identifier: Unlicense
pragma solidity >=0.5.0 <0.9.0;

contract EventContract{
    struct Event{
        address organiser;
        string name;
        uint date;
        uint price;
        uint TotalTickets;
        uint ticketLeft;

    }

    mapping(uint=>Event) public events;
    mapping(address=>mapping(uint=>uint))public tickets;
    uint public nextId;

    function CreateEvent(string memory name,uint date,uint price,uint TotalTickets) external {
    
     require(date>block.timestamp,"WAIT!!! Event has already PAST!!!");
     require(TotalTickets>0,"Hey, Events need atleast 1 ticket");
     events[nextId]=Event(msg.sender,name,date,price,TotalTickets,TotalTickets);
     nextId++;
        

    }

    function buyTicket(uint id, uint Qty) external payable {
        require(events[id].date!=0,"Sorry!!! The Event doesn't Exist.");
        require(events[id].date>block.timestamp,"WAIT!!! Event has already PAST!!!"); 

        Event storage _event = events[id];
        require(msg.value==(_event.price*Qty),"Sorry!!! Not Enough balance");
        require(_event.ticketLeft>=Qty,"Sorry!!! Tickets are SOLD OUT");
        _event.ticketLeft -=Qty;
        tickets[msg.sender][id]+=Qty;



    }



    function transfer(uint eventID, uint quantity, address to)external  
    {
        require(events[eventID].date!=0,"SORRY!!! The Event does not exist");
        require(events[eventID].date>block.timestamp,"SORRY!!! The Event has ended");
        require(tickets[msg.sender][eventID]>=quantity,"SORRY!!! You do not have Enough Tickets");
        tickets[msg.sender][eventID] -= quantity;
        tickets[to][eventID] += quantity;



    }

}