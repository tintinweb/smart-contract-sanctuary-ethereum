//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Sentiments {
    address public owner;
    string[] public tickersArray;

    constructor() {
        owner = msg.sender;
    }

    struct ticker {
        bool exists;
        uint256 up;
        uint256 down;
        mapping(address => bool) Voters;
    }

    event tickerupdated(uint256 up, uint256 down, address voter, string ticker);

    mapping(string => ticker) public Tickers;

    function addTicker(string memory _ticker) public {
        require(msg.sender == owner, "Only the owner can add tickers");
        ticker storage newTicker = Tickers[_ticker];
        newTicker.exists = true;
        tickersArray.push(_ticker);
    }

    function vote(string memory _ticker, bool _vote) public {
        require(Tickers[_ticker].exists, "Ticker does not exist");
        require(!Tickers[_ticker].Voters[msg.sender], "You have already voted");

        ticker storage t = Tickers[_ticker];
        t.Voters[msg.sender] = true;
        if (_vote) {
            t.up++;
        } else {
            t.down++;
        }

        emit tickerupdated(t.up, t.down, msg.sender, _ticker);
    }

    function getTicker(string memory _ticker)
        public
        view
        returns (uint256 up, uint256 down)
    {
        require(Tickers[_ticker].exists, "Ticker does not exist");
        ticker storage t = Tickers[_ticker];
        return (t.up, t.down);
    }
}