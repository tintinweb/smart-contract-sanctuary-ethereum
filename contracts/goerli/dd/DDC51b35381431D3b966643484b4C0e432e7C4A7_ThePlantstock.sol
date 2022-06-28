/**
 *Submitted for verification at Etherscan.io on 2022-06-28
*/

//SPDX-licenseIndentifier: MIT;
pragma solidity 0.8.7;

contract ThePlantstock {

    uint count;
    uint level;

    struct Tock {
        string author;
        string content;
        uint id;
        uint millisec;
    }

    Tock []tockList;

    function createPost(string memory _author, string memory _content, uint _millisec) external {
        count + 1;
        level + 1;
        Tock memory tock = Tock(_author, _content, count, _millisec);
        tockList.push(tock);
       
    }

    function getPosts() public view returns(Tock[] memory) {
        return tockList;
    }

    function timeOfLastPost() public view returns(uint) {
        uint last = tockList.length - 1;
        return tockList[last].millisec;
    }

    function decreaseLevel() public {
        level - 1;
    }

    function getLevel() public view returns(uint) {
        return level;
    }
}