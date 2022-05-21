//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract MarketSentiment {

    address public owner;
    string[] public tickersArray;

    // run at the creation of this smart contract 
    constructor(){

        // whoever at the very first deploys this contract, becomes the owner
        owner = msg.sender;
    }

    // ticker struct
    struct ticker{
        bool exists;
        uint256 upVotes;
        uint256 downVotes;
        mapping (address => bool) Voters;
    }

    mapping (string => ticker) private Tickers;

    event tickerUpdates (
        uint256 upVotes,
        uint256 downVotes,
        address voter,
        string ticker
    );

    function addTicker(string memory _ticker) public {
        // to check if this func is being called by owner
        require(msg.sender == owner, "Only owner is allowed to add tickers");

        // creating new ticker of type ticker, mapping the string _ticker to struct ticker
        ticker storage newTicker = Tickers[_ticker];
        newTicker.exists = true;

        // add new ticker to the array
        tickersArray.push(_ticker);
    }

    function vote(string memory _ticker, bool _vote) public {
        // to check if voted ticker exists
        require(Tickers[_ticker].exists == true, "Ticker does not exist.");
        // to check if voter has not previously voted
        require(!Tickers[_ticker].Voters[msg.sender], "You have already voted");

        // create temporary ticker struct
        ticker storage t = Tickers[_ticker];

        t.Voters[msg.sender] = true;

        if (_vote){
            t.upVotes++;
        }

        else{
            t.downVotes++;
        }

        // call tickerUpdates event

        emit tickerUpdates(t.upVotes, t.downVotes, msg.sender, _ticker);   
    }

    function getVotes(string memory _ticker) public view returns 
        (
            uint256 upVotes,
            uint256 downVotes
        ) {

        // to check if voted ticker exists
        require(Tickers[_ticker].exists == true, "Ticker does not exist.");

        // create temporary ticker struct
        ticker storage t = Tickers[_ticker];

        return (t.upVotes, t.downVotes);    
        }

}