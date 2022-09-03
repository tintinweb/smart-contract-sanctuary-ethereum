// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.8;

// Import this file to use console.log
//import "hardhat/console.sol";

contract Sentiments{

    address public owner;
    string[] public tickersarray;

    constructor(){
        owner = msg.sender;
    }

    struct ticker{
        uint256 up;
        uint256 down;
        bool exists;
        mapping(address => bool) Voters;
    }

    mapping(string => ticker) Tickers;

    event tickerupdated (
        uint256 up,
        uint256 down,
        address voter,
        string ticker
    );

    function addticker(string memory _ticker) public {
        require(msg.sender==owner,"Only onwer can create new tickers");
        ticker storage newticker = Tickers[_ticker];
        newticker.exists = true;
        tickersarray.push(_ticker);
    }

    function updateticker(string memory _ticker, bool _vote) public{
        require(Tickers[_ticker].exists,"No such ticker exists");
        require(!Tickers[_ticker].Voters[msg.sender],"You have already voted");
        ticker storage ti = Tickers[_ticker];
        ti.Voters[msg.sender] = true;
        if(_vote){
            ti.up++;
        }
        else{
            ti.down++;
        }
        emit tickerupdated (ti.up,ti.down,msg.sender,_ticker);
    }

    function getupdown(string memory _ticker) public view returns(uint256 up,uint256 down){
        require(Tickers[_ticker].exists,"No such ticker exists");
        ticker storage t = Tickers[_ticker];
        return (t.up,t.down);
    }

}