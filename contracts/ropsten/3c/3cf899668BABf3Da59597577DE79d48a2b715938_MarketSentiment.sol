/**
 *Submitted for verification at Etherscan.io on 2022-06-25
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract MarketSentiment {

    address public owner;
    string [] public ticketArray;
    struct ticker {
        bool isExists;
        uint256 up;
        uint256 down;
        mapping(address => bool) Voters;

    }
    mapping(string => ticker) private Tickers;

    constructor() {
        owner = msg.sender;
    }
    event tickerUpdated(uint256 up,uint256 down,address voter,string ticker);

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function addTicker(string memory _ticker) public onlyOwner {
        ticker storage newTicker = Tickers[_ticker];
        newTicker.isExists = true;
        ticketArray.push(_ticker);
    }

    function vote(string memory _ticker,bool _vote) public {
        require(Tickers[_ticker].isExists,"Can't vote on this coin");
        require(!Tickers[_ticker].Voters[msg.sender],"You have already voted for this coin");

        ticker storage t = Tickers[_ticker];
        t.Voters[msg.sender] = true;

        if(_vote){
            t.up++;
        } else {
            t.down++;
        }
        emit tickerUpdated(t.up, t.down, msg.sender, _ticker);
    }
    
    function getVotes(string memory _ticker) public view returns(uint256 up,uint256 down){
        require(Tickers[_ticker].isExists,"No such Ticker Defined");
        ticker storage t = Tickers[_ticker];
        return(t.up,t.down);

    }
}