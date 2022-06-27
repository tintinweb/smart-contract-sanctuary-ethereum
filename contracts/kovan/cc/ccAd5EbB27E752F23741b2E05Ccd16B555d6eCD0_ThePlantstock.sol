/**
 *Submitted for verification at Etherscan.io on 2022-06-26
*/

//SPDX-licenseIndentifier: MIT;
pragma solidity 0.8.7;

contract ThePlantstock {

    uint count;

    struct Tock {
        string author;
        string content;
        uint id;
    }

    Tock []tockList;

    function createPost(string memory _author, string memory _content) external {
        count + 1;
        Tock memory tock = Tock(_author, _content, count);
        tockList.push(tock);
    }

    function getPosts() public view returns(Tock[] memory) {
        return tockList;
    }
}