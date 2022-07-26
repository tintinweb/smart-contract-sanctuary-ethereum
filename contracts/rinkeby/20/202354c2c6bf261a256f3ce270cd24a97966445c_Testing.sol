/**
 *Submitted for verification at Etherscan.io on 2022-07-26
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Testing {

    struct Event {
        uint256 id;
        string name;
        uint256 vipPrice;
        uint256 commonPrice;
        uint256 vipMaxSupply;
        uint256 commonMaxSupply;
        uint256 vipCount;
        uint256 commonCount;
        address[] owners;
        uint256[] prices;
    }

    Event[] public events;

    event eventCreated(uint256 _id, string _name, uint256 _vipPrice, uint256 _commonPrice, uint256 _vipMaxSupply, uint256 _commonMaxSupply);

    function createEvent(uint256 _id, string memory _name, uint256 _vipPrice, uint256 _commonPrice, uint256 _vipMaxSupply, uint256 _commonMaxSupply) public {
        require(_vipMaxSupply > 0, "You can organize event only if you create more than 0 tickets");
        require(_commonMaxSupply > 0, "You can organize event only if you create more than 0 tickets");
        address[] memory firstOwner = new address[](_vipMaxSupply + _commonMaxSupply);
        uint256[] memory firstPrice = new uint256[](_vipMaxSupply + _commonMaxSupply);
        for(uint i = 0; i < _vipMaxSupply; i++) {
            firstOwner[i] = address(0x00000);
            firstPrice[i] = _vipPrice;
        }
        for(uint j = _vipMaxSupply; j < firstOwner.length; j++) {
            firstOwner[j] = address(0x00001);
            firstPrice[j] = _commonPrice;
        }
        events.push(Event( _id, _name, _vipPrice, _commonPrice, _vipMaxSupply, _commonMaxSupply, _vipMaxSupply, _commonMaxSupply, firstOwner, firstPrice ));
        emit eventCreated(_id, _name, _vipPrice, _commonPrice, _vipMaxSupply, _commonMaxSupply);
    }

    function getEvents(uint256 _id) public view returns(string memory, uint256, uint256, uint256, uint256, address[] memory, uint256[] memory) {
        return (
            events[_id].name,
            events[_id].vipPrice,
            events[_id].commonPrice,
            events[_id].vipMaxSupply,
            events[_id].commonMaxSupply,
            events[_id].owners,
            events[_id].prices
        );
    }

    function buyTickets(uint256 _id, bool _vipOrNOT, uint256 _quantity) public payable {
        uint count = 0;
        if(_vipOrNOT) {
            require(_quantity <= events[_id].vipCount, "Not enough VIP tickets left for you to purchase.");
            require(msg.value >= events[_id].vipPrice, "Not enough ether to purchase NFTs.");
            for(uint i = 0; i < events[_id].vipMaxSupply; i++) {
                if(count < _quantity) {
                    if(events[_id].owners[i] == address(0x00000)) {
                        events[_id].owners[i] = msg.sender;
                        events[_id].prices[i] = msg.value;
                        count++;
                    }
                }
            }
            events[_id].vipCount -= _quantity; 
        }
        else {
            require(_quantity <= events[_id].commonCount, "Not enough Common tickets left for you to purchase.");
            require(msg.value >= events[_id].commonPrice, "Not enough ether to purchase NFTs.");
            for(uint i = events[_id].vipMaxSupply; i < events[_id].owners.length; i++) {
                if(count < _quantity) {
                    if(events[_id].owners[i] == address(0x00001)) {
                        events[_id].owners[i] = msg.sender;
                        events[_id].prices[i] = msg.value;
                        count++;
                    }
                }
            }
            events[_id].commonCount -= _quantity;
        }
    }

    function getOwnerTickets(uint256 _id, address _add, bool _vipOrNOT) public view returns(bool, uint256) {
        Event memory e = events[_id];
        bool ticketOrNot = false;
        uint256 count = 0;       
        if(_vipOrNOT) {
            for(uint j = 0; j < e.vipMaxSupply; j++) {
                if(e.owners[j] == _add) {
                    ticketOrNot = true;
                    count++;
                }
            }
        }
        else {
            for(uint j = e.vipMaxSupply; j < e.owners.length; j++) {
                if(e.owners[j] == _add) {
                    ticketOrNot = true;
                    count++;
                }
            }
        }
        return (ticketOrNot, count);
    }

    function resellTicket(uint256 _id, bool _vipOrNOT, uint256 _quantity) public payable {
        (bool hasTicketOrNot, uint256 count) = getOwnerTickets(_id, msg.sender, _vipOrNOT);
        require(hasTicketOrNot, "You need to buy some tickets first before reselling.");
        require(_quantity >= count, "You don't have enough tickets for reselling.");
        
    }
}