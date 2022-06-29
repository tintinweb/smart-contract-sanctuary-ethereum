//SPDX-License-Identifier: MIT;
pragma solidity 0.8.7;

contract ThePlantstock {

    uint count;
    uint public level;

    struct Tock {
        string name;
        string tock;
        uint id;
        uint timeStamp;
    }
    
    Tock [] tockList;

    function createTock(string memory _name, string memory _tock, uint _timeStamp) external {
        count = count + 1;
        level = level + 1;
        Tock memory tock = Tock(_name, _tock, count, _timeStamp);
        tockList.push(tock);
    }

    function getAllTocks() external view returns(Tock[] memory) {
        return tockList;
    }

    function decreaseLevel() external {
        level = level - 1;
    }
}