/**
 *Submitted for verification at Etherscan.io on 2022-06-28
*/

//SPDX-license-Identifier: MIT;
pragma solidity 0.8.7;

contract ThePlantstock {

    uint count;

    struct Plant {
        uint health;
    }

    struct Tock {
        string author;
        string content;
        uint id;
        uint millisec;
    }

    Plant [] plantList;
    Tock []tockList;

    function createPost(string memory _author, string memory _content, uint _millisec) external {
        count + 1;
        Tock memory tock = Tock(_author, _content, count, _millisec);
        tockList.push(tock);
        plantList[0].health + 1;
       
    }

    function getPosts() public view returns(Tock[] memory) {
        return tockList;
    }

    function timeOfLastPost() public view returns(uint) {
        uint last = tockList.length - 1;
        return tockList[last].millisec;
    }

    function getHealth() external view returns(uint) {
        return plantList[0].health;
    }

    function createPlant() external {
        Plant memory plant = Plant(5);
        plantList.push(plant);
    }

    function decreaseHealth() external view {
        plantList[0].health - 1;
    }
}