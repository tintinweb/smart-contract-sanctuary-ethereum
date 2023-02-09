/**
 *Submitted for verification at Etherscan.io on 2023-02-09
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TradePortal {

    uint tradeCount = 0;
    address bankAdmin;

    //event NewTrade(address indexed from, uint256 timestamp, string message);

    struct Trade{
        uint TradeId;
        address FromParty;
        address ToParty;
        uint Amount;
        string TradeDate;
        string Status;
    }
    
    Trade[] trades;


    constructor() {
        bankAdmin = msg.sender;
    }

    modifier onlyBankAdmin(){
        require(msg.sender == bankAdmin, "You do not have Administrative Priviledges!");
        _;
    }

    function getAllTrades() public view returns(Trade[] memory){
        return trades;
    }
    

    function submitTrade(uint TradeId, 
    address FromParty, 
    address ToParty, 
    uint Amount, 
    string memory TradeDate) public onlyBankAdmin{

        trades.push(Trade(TradeId, FromParty, ToParty, Amount, TradeDate, "SUBMITTED"));
        tradeCount++;
        //emit NewGreet(msg.sender, block.timestamp, _message);

    }

    function markSettled(uint TradeId) public {
        trades[TradeId-1].Status = "SETTLED";
    }

    function getTradeCount() public view returns(uint){
        return tradeCount;
    }
}