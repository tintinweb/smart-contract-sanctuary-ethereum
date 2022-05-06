//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


contract DataBaseForMarketTest {

    struct advertisments {
        string zapis;
    }

    //advertisments[] public arrWithStructs;

    mapping(address => advertisments[]) public numberOfAdvertismentsOfUser;

    //mapping(uint256 => advertisments) public accountAdvertisments;

    function getNumberOfAdvertismets() external view returns(uint256) {
        return (numberOfAdvertismentsOfUser[msg.sender].length);
    }

    function zapis(string memory _str) external {
        advertisments[] storage listOfAdvertisments = numberOfAdvertismentsOfUser[msg.sender];

        listOfAdvertisments.push(advertisments(_str));
    }


    function getZapis(uint256 numberOfAdvertisment) external view returns(advertisments memory){  
        advertisments[] storage arr = numberOfAdvertismentsOfUser[msg.sender];
        advertisments storage res = arr[numberOfAdvertisment];
        return(res);
    }

    constructor() {}
}