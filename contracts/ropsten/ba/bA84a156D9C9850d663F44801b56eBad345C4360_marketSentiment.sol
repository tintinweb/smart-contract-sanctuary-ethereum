//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract marketSentiment{

    address public owner;
    string[] public ticketsArray;

    constructor(){
        owner=msg.sender;
    }

    struct ticker{
        bool exists;
        uint256 up;
        uint256 down;
        mapping(address=> bool) voters;
    }
    event tikcerupdated(uint256 up, uint256 down, address voter, string ticker);

    mapping(string => ticker) private Tickers;

    function addTicker (string memory _option)public {
        require(owner==msg.sender, "Only owner can call this function");
        ticker storage newTicker=Tickers[_option];
        newTicker.exists=true;
        ticketsArray.push(_option);
    }

    function vote(string memory _option, bool _vote)public{
        require(Tickers[_option].exists==true, "Coin doesn't exists");
        require(Tickers[_option].voters[msg.sender]==false,"You've already voted!");
        Tickers[_option].voters[msg.sender]=true;
        if(_vote==true){
            Tickers[_option].up++;
        }else{
            Tickers[_option].down++;
        }
        emit tikcerupdated(Tickers[_option].up, Tickers[_option].down, msg.sender, _option);
    }

    function getVotes(string memory _option)public view returns(uint256, uint256){
        require(Tickers[_option].exists, "Coin does't exists");
        return (Tickers[_option].up, Tickers[_option].down);
    }



}