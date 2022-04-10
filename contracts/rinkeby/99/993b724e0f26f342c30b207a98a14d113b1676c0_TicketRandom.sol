/**
 *Submitted for verification at Etherscan.io on 2022-04-09
*/

//SPDX-License-Identifier: MTI

pragma solidity ^0.8.7;

contract TicketRandom{

    uint public _priceTicket = 0.004 ether;

    uint public _countTransaction=0;

    address private _ownerAddress;

    uint public _ticket = _numberRandom();

    address[] public addressWithTickets;
    
    mapping(address => uint16[]) public addressTickets;

    //mapping(address => uint) private addressWins;

    address[] addressWinsList;
    


    constructor (){
        _ownerAddress = msg.sender;
    }

    function updatePriceTicket(uint _newPrice) public {
        require(msg.sender == _ownerAddress);
        _priceTicket = _newPrice;
    }
    function _numberRandom() private returns(uint16){
        _countTransaction++;
        uint16 n = uint16(uint256(keccak256(abi.encodePacked(block.timestamp,msg.sender))) * _countTransaction / 251 % 10);
        return n;
    }


    function buyTicket() public payable{
        require( msg.value == _priceTicket);
        addressTickets[msg.sender].push(_numberRandom());
        addressWithTickets.push(msg.sender);
        payable(_ownerAddress).transfer(msg.value / 10);
    }

    function verificWins() public {
        require(msg.sender == _ownerAddress);
        for(uint x=0;x<addressWithTickets.length;x++){
            for(uint y=0;y<addressTickets[addressWithTickets[x]].length; y++){
                if(addressTickets[addressWithTickets[x]][y] == _ticket){
                    addressWinsList.push(addressWithTickets[x]);
                }
            }
        }
        if(addressWinsList.length == 0 ){
            uint payWins = address(this).balance / addressWithTickets.length;
            for(uint y=0;y<addressWithTickets.length; y++){
                payable(addressWithTickets[y]).transfer(payWins);
            }
        }
        else{
            uint payWins = address(this).balance / addressWinsList.length;
            for(uint y=0;y<addressWinsList.length; y++){
                payable(addressWinsList[y]).transfer(payWins);
            }
        }   
    }
}