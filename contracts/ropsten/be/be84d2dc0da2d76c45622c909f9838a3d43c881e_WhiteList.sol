/**
 *Submitted for verification at Etherscan.io on 2022-05-15
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract WhiteList {
    string[] private whiteList;
    string private randomText;
    address public owner;

    constructor(string[] memory _whiteList, string memory _randomText) {
        whiteList = _whiteList;
        randomText = _randomText;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Sorry, you are not the owner.");
        _;
    }

    function setOwner(address _owner) external onlyOwner {
        require(_owner != address(0), "Invalid address");
        owner = _owner;
    }

    function getWhiteList() public view returns (string[] memory) {
        return whiteList;
    }

    function getRandomText() public view returns (string memory) {
        return randomText;
    }

    function setWhiteList(string[] memory _whiteList) external onlyOwner {
        whiteList = _whiteList;
    }
}