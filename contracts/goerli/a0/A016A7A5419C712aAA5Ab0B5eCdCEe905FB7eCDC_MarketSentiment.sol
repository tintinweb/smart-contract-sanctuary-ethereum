// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

error MarketSentiment__notOwner();
error MarketSentiment__isTickerPresent();
error MarketSentiment__hasVoted();

contract MarketSentiment {
    address private immutable i_owner;
    string[] private s_tickersArray;
    mapping(string => ticker) private s_Tickers;

    constructor() {
        i_owner = msg.sender;
    }

    struct ticker {
        bool exists;
        uint256 up;
        uint256 down;
        mapping(address => bool) Voters;
    }

    event tickerUpdated(uint256 up, uint256 down, address voter, string ticker);

    // functions
    function addTicker(string memory _ticker) public notOwner {
        ticker storage newTicker = s_Tickers[_ticker];
        newTicker.exists = true;
        s_tickersArray.push(_ticker);
    }

    function vote(string memory _ticker, bool _vote)
        public
        isTickerPresent(_ticker)
        hasVoted(_ticker)
    {
        ticker storage t = s_Tickers[_ticker];
        t.Voters[msg.sender] = true;

        if (_vote) {
            t.up++;
        } else {
            t.down++;
        }

        emit tickerUpdated(t.up, t.down, msg.sender, _ticker);
    }

    function getVotes(string memory _ticker)
        public
        view
        isTickerPresent(_ticker)
        returns (uint256 up, uint256 down)
    {
        ticker storage t = s_Tickers[_ticker];
        return (t.up, t.down);
    }

    // modify
    modifier notOwner() {
        if (msg.sender != i_owner) {
            revert MarketSentiment__notOwner();
        }
        _;
    }

    modifier isTickerPresent(string memory _ticker) {
        if (!s_Tickers[_ticker].exists) {
            revert MarketSentiment__isTickerPresent();
        }
        _;
    }
    modifier hasVoted(string memory _ticker) {
        if (s_Tickers[_ticker].Voters[msg.sender]) {
            revert MarketSentiment__hasVoted();
        }
        _;
    }
}