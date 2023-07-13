pragma solidity ^0.8.4;
// SPDX-License-Identifier: GPL-3.0-or-later

contract ChapterStorage{
    string[] public chapters;
    
    // set to onlyOwner()
    // check if value exists - 
    constructor(){
        chapters.push('');
        chapters.push('Acknowledgment1');
        chapters.push('Acknowledgment2');
        chapters.push('Acknowledgment3');
        chapters.push('Acknowledgment4');
        chapters.push('Acknowledgment5');
        chapters.push('Acknowledgment6');
        chapters.push('Acknowledgment7');
        chapters.push('Acknowledgment8');
    }
    function set(uint256 location, string calldata _unit) external {
        chapters[location] = _unit;
    }
    //Returns the currently stored unsigned integer
    function get(uint256 location) public view returns (string memory) {
        return chapters[location];
    }

}