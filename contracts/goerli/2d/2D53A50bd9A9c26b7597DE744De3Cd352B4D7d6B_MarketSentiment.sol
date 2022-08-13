// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract MarketSentiment {
    address public immutable i_owner;
    string[] public tickersArray;

    struct Ticker {
        bool exists;
        uint256 up;
        uint256 down;
        mapping(address => bool) Voters;
    }

    event tickerUpdated(uint256 up, uint256 down, address voter, string ticker);

    mapping(string => Ticker) private Tickers;

    constructor() {
        i_owner = msg.sender;
    }

    function addTicker(string memory _ticker) public {
        require(msg.sender == i_owner, 'Only the i_owner can create tickers');
        Ticker storage newTicker = Tickers[_ticker];
        newTicker.exists = true;
        tickersArray.push(_ticker);
    }

    function vote(string memory _ticker, bool _vote) public {
        require(Tickers[_ticker].exists, "Can't vote on this coin");
        require(
            !Tickers[_ticker].Voters[msg.sender],
            'You have already voted for this coin'
        );
        Ticker storage t = Tickers[_ticker];
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
        returns (uint256 up, uint256 down)
    {
        require(Tickers[_ticker].exists, 'No such Ticker Defined');
        Ticker storage t = Tickers[_ticker];
        return (t.up, t.down);
    }
}