// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract BlooDonation {

    address public owner;
    string[] public tickersArray;

    constructor() {
        owner = msg.sender;
    }

    struct ticker {
        bool exists;
        uint256 up;
        uint256 down;
        mapping(address => bool) Donors;
    }

    event tickerupdated (
        uint256 up,
        uint256 down,
        address donor,
        string ticker
    );

    mapping(string => ticker) private Tickers;

    function addTicker(string memory _ticker) public {
        require(msg.sender == owner, "Only the owner can create tickers");
        ticker storage newTicker = Tickers[_ticker];
        newTicker.exists = true;
        tickersArray.push(_ticker);
    }

    function donate(string memory _ticker, bool _donate) public {
        require(Tickers[_ticker].exists, "Can't donate");
        require(!Tickers[_ticker].Donors[msg.sender], "You have already donate");
        

        ticker storage t = Tickers[_ticker];
        t.Donors[msg.sender] = true;

        if(_donate){
            t.up++;
        } else {
            t.down++;
        }

        emit tickerupdated (t.up,t.down,msg.sender,_ticker);
    }

    function getDonors(string memory _ticker) public view returns (
        uint256 up,
        uint256 down
    ){
        require(Tickers[_ticker].exists, "No such Ticker Defined");
        ticker storage t = Tickers[_ticker];
        return(t.up,t.down);
        
    }
    


}