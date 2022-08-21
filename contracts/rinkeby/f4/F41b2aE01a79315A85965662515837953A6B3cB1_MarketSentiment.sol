// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


contract MarketSentiment {
  // the address pf the owner of the smart contract: the person who can add new tickers
  address public owner;
  // all of the cryptocurrencies that have been set by the owner
  string[] public tickersArray; 

  constructor(){
    owner = msg.sender;
  }

  struct ticker {
    bool exists;
    uint256 up;
    uint256 down;
    mapping(address => bool) voters;
  }

  // event when a ticker is updated
  event tickerUpdated (
    uint256 up,
    uint256 down,
    address voter,
    string ticker
  );

  // maps name of tickers to their information
  mapping (string => ticker) private Tickers;

  // can only add a ticker if you are the owner of the smart contract 
  function addTicker(string memory _ticker) public {
    require(msg.sender == owner, "Only the owner can add new currencies");
    // automatically creates a Ticker object for us by just indexing into that the parameter string
    ticker storage newTicker = Tickers[_ticker];
    newTicker.exists = true;
    tickersArray.push(_ticker);
  }

  function vote(string memory _ticker, bool _vote) public {
    require(Tickers[_ticker].exists, "Can't Vote on this coin");
    require(Tickers[_ticker].voters[msg.sender] == false, "You can not double vote");
    ticker storage t = Tickers[_ticker];
    t.voters[msg.sender] = true;
    if (_vote) t.up++;
    else t.down--;
    emit tickerUpdated (t.up,t.down,msg.sender,_ticker);
  }

  function get_votes(string memory _ticker) public view returns (uint256 up, uint256 down){
    require(Tickers[_ticker].exists, "No such currency exists");
    return( Tickers[_ticker].up , Tickers[_ticker].down);
  }

}