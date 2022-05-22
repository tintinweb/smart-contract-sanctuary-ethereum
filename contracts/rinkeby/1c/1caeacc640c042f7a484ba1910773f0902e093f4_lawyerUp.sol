/**
 *Submitted for verification at Etherscan.io on 2022-05-22
*/

// SPDX-License-Identifier: NONE

pragma solidity ^0.8.4;

contract lawyerUp {
    address private owner;
    struct laywer {
        uint256 _id;
        string _Name;
        string _imglink;
        uint256 licenceId;
    }
    mapping (uint256 => laywer) public laywerId;
    uint256 public totalLaywers;
    laywer[] private laywers;

    modifier onlyOwner() {
        require(msg.sender == owner,"Not Allowed");
        _;
    }
    constructor(){
        owner = msg.sender;
    }
 
    function addLawyer(string memory _name, string memory _iLink, uint256 _id) public onlyOwner {
        uint256 _lId = totalLaywers + 1;
        laywerId[_lId] = laywer(_lId, _name, _iLink, _id);
        laywers.push(laywerId[_lId]);
        totalLaywers++;

    }
    function getAllLawyers() public view returns(laywer[] memory) {
        return laywers;
    }

}