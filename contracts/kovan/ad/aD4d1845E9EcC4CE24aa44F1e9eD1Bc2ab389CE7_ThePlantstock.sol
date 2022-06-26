/**
 *Submitted for verification at Etherscan.io on 2022-06-26
*/

//SPDX-licenseIndentifier: MIT;
pragma solidity 0.8.7;

contract ThePlantstock {

    uint public favoriteNumber = 3;

    uint count;

    struct Tock {
        string author;
        string content;
        string date;
        uint id;
    }

    Tock []tockList;

    function createPost(string memory _author, string memory _content, string memory _date) external {
        count + 1;
        Tock memory tock = Tock(_author, _content, _date, count);
        tockList.push(tock);
    }

    function getPosts() public view returns(Tock[] memory) {
        return tockList;
    }

    function getNumber() public view returns(uint) {
        return favoriteNumber;
    }

}