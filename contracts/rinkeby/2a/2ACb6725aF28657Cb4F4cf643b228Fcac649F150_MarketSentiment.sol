//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

contract MarketSentiment {
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

    event tickerupdated(
        uint256 up,
        uint256 down,
        address voterm,
        string ticker
    );

    mapping(string => ticker) Tickers;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can do this!!!");
        _;
    }

    function addTicker(string memory _ticker) external onlyOwner {
        ticker storage newTicker = Tickers[_ticker];
        newTicker.exists = true;
        tickersArray.push(_ticker);
    }

    function vote(string memory _ticker, bool _vote) external {
        require(Tickers[_ticker].exists, "Ticker not exist!!!");
        require(
            !Tickers[_ticker].Voters[msg.sender],
            "You have already voted for this!!!"
        );

        ticker storage t = Tickers[_ticker];
        t.Voters[msg.sender] = true;

        if (_vote) {
            t.up++;
        } else {
            t.down++;
        }

        emit tickerupdated(t.up, t.down, msg.sender, _ticker);
    }

    function getVotes(string memory _ticker)
        external
        view
        returns (uint256 up, uint256 down)
    {

    }
}