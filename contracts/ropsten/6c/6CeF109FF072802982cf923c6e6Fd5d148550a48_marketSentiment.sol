//SPDX-License-Identifier: Mit

pragma solidity ^0.8.0;

contract marketSentiment {
    address public owner;
    string[] public tickerArray;

    constructor(){
        owner = msg.sender;
    }
    
    struct ticker {
        bool exists;
        uint256 up;
        uint256 down;
        mapping(address => bool) Voters;
    }

    event tickerUpdated(
        uint256 up,
        uint256 down,
        address voter,
        string ticker
    );

    mapping (string => ticker) private Tickers;


    function addTicker (string memory _ticker) public {
            require(msg.sender == owner, "Only the owner can" );
            ticker storage newTicker = Tickers[_ticker];
            newTicker.exists = true;
            tickerArray.push(_ticker);
        }

    function vote (string memory _ticker, bool _vote) public {
            require(Tickers[_ticker].exists, "Can't vote ");
            require(!Tickers[_ticker].Voters[msg.sender], "No Vote");

            ticker storage t = Tickers[_ticker];
            t.Voters[msg.sender] = true;

            if(_vote){
            t.up += 1;
            }else{
            t.down;
            }

            emit tickerUpdated(t.up, t.down, msg.sender, _ticker);
        }

        function getVotes (string memory _ticker) public view returns (
            uint256 up,
            uint256 down) {
            require(Tickers[_ticker].exists, "No ticker" );
            ticker storage t = Tickers[_ticker];
            return(t.up, t.down);
        }


    }