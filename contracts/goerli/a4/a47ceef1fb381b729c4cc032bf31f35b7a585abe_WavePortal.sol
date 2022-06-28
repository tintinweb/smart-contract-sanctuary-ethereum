/**
 *Submitted for verification at Etherscan.io on 2022-06-28
*/

// File: WavePortal.sol
// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

// @uthor : carlito
// Based on buildspace exercices (https://buildspace.so/p/build-solidity-web3-app/lessons/store-data-on-smart-contract)





contract WavePortal {
    struct Wave {
        uint id;
        uint date;
        string content;
        string author;
        address addressAuthor;
    }

    Wave[] public waves;

    //mapping(uint => Wave) public waves;
    //mapping(address => uint) public wavers;
    uint private totalWaves;

    constructor() {
        totalWaves = 0;
    }



    function sendWave(string memory _content, string memory _author) public {
        waves.push(Wave(totalWaves, block.timestamp, _content, _author, msg.sender));
       //waves[totalWaves] = Wave(totalWaves, block.timestamp, _content, _author, msg.sender);
        ++totalWaves;
    
    }


    function getTotalWaves() public view returns (uint256) {

        return totalWaves;
    }

    function getWaves() public view returns (address[] memory, string[] memory) {

        address[] memory _addrs = new address[](totalWaves);
        string[] memory _content = new string[](totalWaves);
        string[] memory _author = new string[](totalWaves);
        
            for (uint i = 0; i < totalWaves; i++) {
                Wave storage _wave = waves[i];
                _addrs[i] = _wave.addressAuthor;
                _content[i] = _wave.content;
                _author[i] = _wave.author;
            }

        return (_addrs, _content);
    }

    function wafesOf(address _account) public view returns (string[] memory) {
        string[] memory _content = new string[](10);
        uint counter = 0;

        for (uint i = 0; i < totalWaves; i++) {
            Wave storage _wave = waves[i];
            if (_wave.addressAuthor == _account) { 
                _content[counter] = _wave.content;
                counter++;
            }
        }

        return (_content);
    }


    function totalWafesOf(address _account) public view returns(uint) {
        uint count = 0;

        for (uint i = 0; i < totalWaves; i++) {
            Wave storage _wave = waves[i];
            if (_wave.addressAuthor == _account) {
                count++;
            }
        }
        return(count);
    }
        
}