// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Wave{

    string waves;

    function setWaves ( string memory _waves) public {
        waves = _waves;
    }
    function getWaves() public view returns(string memory){
        return waves;
    }
    
}