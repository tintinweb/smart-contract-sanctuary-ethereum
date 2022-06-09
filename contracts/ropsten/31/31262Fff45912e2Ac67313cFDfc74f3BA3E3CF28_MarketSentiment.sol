//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract MarketSentiment {

    address public Owner;
    string[] public TickersArray;

    constructor () {
        Owner = msg.sender;
    }

    struct ticker{
        bool exists;
        uint256 up;
        uint256 down;
        mapping(address => bool) voters;
    }

    event tickerupdated (
        uint256 up,
        uint256 down,
        address voter,
        string ticket
    );

    mapping (string => ticker) Tickers;

    function addticker(string memory _ticker) public {
        require (msg.sender == Owner, "only the owner can create tickets");
        ticker storage newticker = Tickers[_ticker];

        newticker.exists = true;
        TickersArray.push(_ticker);

    }
    function vote(string memory _ticker, bool voted) public {
        require (Tickers[_ticker].exists, "ticker doesent exists");
        require (!Tickers[_ticker].voters[msg.sender], "member already voted for this ticker");

        ticker storage t = Tickers[_ticker];
        
        if (voted){
            t.up ++;
        }else {
            t.down ++;
        }
        t.voters[msg.sender] = true;
        
        emit tickerupdated(t.up, t.down, msg.sender, _ticker );
    }

    function getVoters(string memory _ticker) public view returns(uint , uint){
        require (Tickers[_ticker].exists, "ticker doesent exists");
        ticker storage t = Tickers[_ticker];

        return (t.up, t.down);
    }
}