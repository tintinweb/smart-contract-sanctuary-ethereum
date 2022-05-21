// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract VoteTicker {
    address public owner; // address of the owner of the smart contract
    string[] public tickerArray; // array of ticker set by the owner

    constructor() {
        owner = msg.sender; // Set the owner to the deployer of the smart contract
    }

    // Definition of the crypto currency added to this smart contact
    struct ticker {
        bool exists;
        uint256 up; // how many wallets have voted up
        uint256 down; // how many wallets have voted down for this
        mapping(address => bool) Voters; // address mapped to a bool any time someone votes, for this ticker, he can't vote any
    }

    event tickerUpdated (
        uint256 up,
        uint256 down,
        address voter,
        string ticker
    );

    mapping(string => ticker) private Tickers;

    // Add ticker by the owner of the smart contract
    function addTicker(string memory _ticker) public {
        require(msg.sender == owner, "only the owner can create ticker");
        ticker storage newTicker = Tickers[_ticker];
        newTicker.exists = true;
        tickerArray.push(_ticker);
    }

    function vote(string memory _ticker, bool _vote) public {
        require(Tickers[_ticker].exists, "Can't vote on this coin"); // Check if coin exist in smart contract
        require(!Tickers[_ticker].Voters[msg.sender], "You have already voted for this coin"); // Check if user has voted for the coin before.
        
        ticker storage t = Tickers[_ticker];
        t.Voters[msg.sender] = true;
        
        if(_vote) {
            t.up++;
        } else {
            t.down++;
        }

        emit tickerUpdated(t.up, t.down, msg.sender, _ticker);
    }

    function getVotes(string memory _ticker) public view returns (
        uint256 up,
        uint256 down
    ) {
        require(Tickers[_ticker].exists, "No such Ticker Defined");
        ticker storage t = Tickers[_ticker];
        return(t.up, t.down);
    }
}