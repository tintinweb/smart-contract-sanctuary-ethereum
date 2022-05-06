//SPDX-License-Identifier: MIT
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


    function getZapis(address _address, uint256 numberOfAdvertisment) external view returns(advertisments memory){  
        // advertisments[] memory arr = numberOfAdvertismentsOfUser[msg.sender];
        // advertisments memory res = arr[numberOfAdvertisment];
        // return(res);

        return(numberOfAdvertismentsOfUser[_address][numberOfAdvertisment]);
    }

    constructor() {}
}