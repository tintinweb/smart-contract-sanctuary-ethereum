pragma solidity ^0.8.4;
// SPDX-License-Identifier: GPL-3.0-or-later

contract ChapterStorage{
    string[] public chapters;
    
    // set to onlyOwner()
    // check if value exists - 
    constructor(){
        chapters.push('');
        chapters.push('Acknowledgment');
        chapters.push('Acknowledgment');
        chapters.push('Acknowledgment');
        chapters.push('Acknowledgment');
        chapters.push('Acknowledgment');
        chapters.push('Acknowledgment');
        chapters.push('Acknowledgment');
        chapters.push('Acknowledgment');
    }
    function set(uint256 location, string calldata _unit) external {
        chapters[location] = _unit;
    }
    //Returns the currently stored unsigned integer
    function get(uint256 location) public view returns (string memory) {
        return chapters[location];
    }

}