// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract HackathonOracle{

    struct Data {
        string symbol;
        string high;
        string low;
        string open;
        string close;
        string date;
    }

    mapping(string => Data) public cids;

    event SetData(string symbol, string high, string low, string open, string close, string date);

    function readData(string memory cid) public view returns(Data memory){
        Data memory data = cids[cid];
        return data;
    }

    function setData(string memory symbol, string memory high, string memory low, string memory open, string memory close, string memory date, string memory cid) public {
        Data memory data = Data(symbol, high, low, open, close, date);
        cids[cid] = data;
        emit SetData(symbol, high, low, open, close, date);
    }

}