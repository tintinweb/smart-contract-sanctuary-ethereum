// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

contract MarketSentiment {
    address public owner;
    string[] public tickersArray;

    constructor() {
        owner = msg.sender; // who deploys the contract will be the owner
    }

    struct ticker {
        bool exists;
        uint256 up;
        uint256 down;
        mapping(address => bool) Voters;
        // for every address the bool
        // is set to false, once voted the bool will be set to true
    }

    // for the sake of transparency and for moralis to be able to listen
    // to any events and get to Moralis database
    event tickerupdated(uint256 up, uint256 down, address voter, string ticker);

    // takes any string (crypto) and maps it to a ticker struct
    // fundamental for add tickers function
    mapping(string => ticker) private Tickers;

    function addTicker(string memory _ticker) public {
        require(msg.sender == owner, "Only owner can create tickers");
        ticker storage newTicker = Tickers[_ticker];
        // the struct ticker will store the newTicker which will be an array
        // with called function string
        newTicker.exists = true;
        tickersArray.push(_ticker); // adding the new ticker in tickersArray
    }

    function vote(string memory _ticker, bool _vote) public {
        require(Tickers[_ticker].exists, "Can't vote on this coin");
        require(
            !Tickers[_ticker].Voters[msg.sender],
            "You have already voted for this coin"
        );

        // create a temporary ticker struct for the ticker that we are after
        ticker storage t = Tickers[_ticker];
        t.Voters[msg.sender] = true; // changing the state of the voter being equal to true

        // since _vote is a bool, the vote will have the following sequence
        //true = up, false = down
        if (_vote) {
            t.up++;
        } else {
            t.down++;
        }

        // being able to notice with moralis whhen a new vote has been made
        emit tickerupdated(t.up, t.down, msg.sender, _ticker);
    }

    // based on the string wich will be the ticket it returns the votes
    function getVotes(string memory _ticker)
        public
        view
        returns (uint256 up, uint256 down)
    {
        require(Tickers[_ticker].exists, "No such Ticker Defined");
        ticker storage t = Tickers[_ticker];
        return (t.up, t.down);
    }
}