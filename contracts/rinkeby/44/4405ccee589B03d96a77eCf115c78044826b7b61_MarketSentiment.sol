// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
contract MarketSentiment {
    address public owner;
    string[] public tickersArray;
    struct ticker {
        bool exists;
        uint256 up;
        uint256 down;
        string tickerName;
        mapping(address => bool) Voters;
    }
    event tickerupdated (
        uint256 up,
        uint256 down,
        address voter,
        string ticker
    );
    mapping(string => ticker) private Tickers;
    constructor () {
        owner = msg.sender;
    }
    modifier isOwner(){
        require(msg.sender == owner, "you are not the owner");
        _;
    }

    modifier tickerExists(string memory _ticker){
        require(Tickers[_ticker].exists, "no such ticker exists");
        _;
    }

    modifier firstVote(string memory _ticker){
        require(!Tickers[_ticker].Voters[msg.sender], "you have already voted");
        _;
    }

    function addTicker(string memory _ticker) public isOwner{
        ticker storage newTicker = Tickers[_ticker];
        newTicker.tickerName = _ticker;
        newTicker.exists = true;
        tickersArray.push(_ticker);
    }
    function vote(bool _vote, string memory _ticker) public tickerExists(_ticker) firstVote(_ticker){
        ticker storage newTicker = Tickers[_ticker];
        newTicker.Voters[msg.sender] = true;
        if(_vote){
            newTicker.up++;
        }else{
            newTicker.down++;
        }
        emit tickerupdated(newTicker.up,newTicker.down,msg.sender,_ticker);
    }
    function getVotes(string memory _ticker) public view tickerExists(_ticker) returns(
        uint256 up,
        uint256 down
    ){
        ticker storage t = Tickers[_ticker];
        return (t.up,t.down);
    }
}