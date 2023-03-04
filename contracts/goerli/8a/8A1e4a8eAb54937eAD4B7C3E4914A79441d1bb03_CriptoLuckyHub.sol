/**
 *Submitted for verification at Etherscan.io on 2023-03-04
*/

// SPDX-License-Identifier: MIT
// File: docs.chain.link/samples/VRF/CriptoLuckyHub.sol


pragma solidity ^0.8.7;
struct ActualLottery{
    uint  idGame;
    uint  prize;
    uint  pool;
    uint  costTicket;
    uint  maxTicketsPlayer;
    bool  active;
    //total tickets already sold
    uint  totalTickets;
    //total tickets on sale
    uint  maxTickets;
    uint32  Nwinners;
  }
  
interface CriptoLucky{
    function createLottery(uint _cost,uint _maxTicketsPlayer,uint32 _Nwinners,uint _maxTickets,uint _percentage)external;
    function joinFromHub(address _wallet,uint tickets) external payable;
    function getWinners(uint256 id)external view returns (address[] memory);
    function getIfWinners(uint256 id)external view returns (bool[] memory);
    function getNmofTicketsBought(address addr)external view returns (uint);
    function endGame() external;
    function withdrawByWinnerFromHub(address _address,uint _idGame)external;
    function _ActualLottery() external view returns (ActualLottery memory);

}

contract CriptoLuckyHub{
    address s_owner;
    mapping(uint => CriptoLucky)public contracts;
    uint nContracts;
    constructor(){
    s_owner=msg.sender;
    nContracts=0;
    }
    function addLottery(address _addr)public onlyOwner{
        nContracts++;
        contracts[nContracts]=CriptoLucky(_addr);
    }
    function createLottery(uint _id,uint _cost,uint _maxTicketsPlayer,uint32 _Nwinners,uint _maxTickets,uint _percentage)public onlyOwner{
        contracts[_id].createLottery(_cost,_maxTicketsPlayer,_Nwinners,_maxTickets,_percentage);
    }

    function join(uint _id,uint _tickets) public payable{
        contracts[_id].joinFromHub{value:msg.value}(msg.sender,_tickets);
    }

    function endGame(uint _id) public onlyOwner{
        contracts[_id].endGame();
    } 

    function getWinners(uint _idContract, uint _idLottery) public view returns(address[]memory){
        return contracts[_idContract].getWinners(_idLottery);
    }
    function getIfWinners(uint _idContract, uint _idLottery) public view returns(bool[]memory){
        return contracts[_idContract].getIfWinners(_idLottery);
    }
    function getInfoLottery(uint _idContract) public view returns(ActualLottery memory){
        return contracts[_idContract]._ActualLottery();
    }
    function getNmofTicketsBought(uint _idContract, address _addr) public view returns(uint){
        return contracts[_idContract].getNmofTicketsBought(_addr);
    }
    function withdrawByWinner(uint _idContract, uint _idLottery)public  {
        contracts[_idContract].withdrawByWinnerFromHub(msg.sender,_idLottery);
    }

    modifier onlyOwner() {
        require(msg.sender == s_owner);
        _;
    }
    

}