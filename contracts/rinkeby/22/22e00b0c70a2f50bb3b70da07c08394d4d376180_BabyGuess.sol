/**
 *Submitted for verification at Etherscan.io on 2022-06-21
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <= 0.9.0;

contract BabyGuess {

    struct Players {
        string name;
        uint256 weight;
        uint256 height;
        string hairColor;
        string eyeColor;
        uint date;
    }

    Players[] public players;
    mapping(string => uint256) public nameToWeight;
    mapping(string => uint256) public nameToHeight;
    mapping(string => string) public nameToHairColor;
    mapping(string => string) public nameToEyeColor;
    mapping(string => uint) public nameToDate;

    function playerGuess(string memory _name, uint256 _weight, uint256 _height, string memory _hairColor, string memory _eyeColor, uint _date) public {
        players.push(Players(_name, _weight, _height, _hairColor, _eyeColor, _date));
        nameToWeight[_name] = _weight;
        nameToHeight[_name] = _height;
        nameToHairColor[_name] = _hairColor;
        nameToEyeColor[_name] = _eyeColor;
        nameToDate[_name] = _date;
    }

}