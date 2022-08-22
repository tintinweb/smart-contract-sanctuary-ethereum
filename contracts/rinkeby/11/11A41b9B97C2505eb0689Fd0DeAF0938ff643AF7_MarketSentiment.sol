//SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract MarketSentiment {
    event TickerUpdated(uint256 up, uint256 down, address voter, string ticker);

    struct ticker {
        bool exists;
        uint256 up;
        uint256 down;
        mapping(address => bool) Voters;
    }

    address public owner;
    string[] public tickersArray;
    mapping(string => ticker) private Tikers;

    constructor() {
        owner = msg.sender;
    }

    function addTicker(string memory _ticker) public {
        require(msg.sender == owner, "Only the owner can create tickers");
        ticker storage newTicker = Tikers[_ticker];
        newTicker.exists = true;
        tickersArray.push(_ticker);
    }

    function vote(string memory _ticker, bool _vote) public {
        require(Tikers[_ticker].exists, "Can't vote on this coin");
        require(!Tikers[_ticker].Voters[msg.sender], "You have already voted");

        ticker storage t = Tikers[_ticker];
        t.Voters[msg.sender] = true;
        if (_vote) {
            t.up++;
        } else {
            t.down++;
        }
        emit TickerUpdated(t.up, t.down, msg.sender, _ticker);
    }

    function getVotes(string memory _ticker) public view returns (uint256 up, uint256 down) {
        require(Tikers[_ticker].exists, "No suck Ticker exists");
        ticker storage t = Tikers[_ticker];
        return (t.up, t.down);
    }
}