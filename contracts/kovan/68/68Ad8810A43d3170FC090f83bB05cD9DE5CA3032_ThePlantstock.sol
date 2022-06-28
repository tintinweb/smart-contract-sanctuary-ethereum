/**
 *Submitted for verification at Etherscan.io on 2022-06-27
*/

//SPDX-licenseIndentifier: MIT;
pragma solidity 0.8.7;

contract ThePlantstock {

    uint count;
    uint public level = 5;

    struct Tock {
        string author;
        string content;
        uint id;
        uint millisec;
    }

    Tock []tockList;

    function createPost(string memory _author, string memory _content, uint _millisec) external {
        count + 1;
        Tock memory tock = Tock(_author, _content, count, _millisec);
        tockList.push(tock);
        if(level >= 5) {
            level = 5;
        } else {
            level + 1;
        }
    }

    function getPosts() public view returns(Tock[] memory) {
        return tockList;
    }

    function timeOfLastPost() public view returns(uint) {
        uint last = tockList.length - 1;
        return tockList[last].millisec;
    }

    function decreaseLevel(uint _byNum) public {
        if(level <= 1) {
            level = 1;
        } else {
            level - _byNum;
        }
    }
}