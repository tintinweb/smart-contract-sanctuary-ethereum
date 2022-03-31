/**
 *Submitted for verification at Etherscan.io on 2022-03-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract UserAddressAndAmount {
    struct data1 {
        address userAddress;
        uint256 amount;
        uint256 date;
    }
    mapping(uint256=>data1) public getDataByNumber;

    struct data {
        address userAddress;
        uint256 amount;
        uint256 date;
    }
    mapping(uint256=>data) Address;
    uint256[] arrayId1;
    uint256[] arrayId2;
    function addData(address[] memory userAddress, uint256[] memory amount, uint256[] memory date) public {
        require(userAddress.length <= 100, "Length is not greater than 100!");
        require(userAddress.length == amount.length, "Length has mistmatch!");
        require(amount.length == date.length, "Length has mistmatch!");
        for(uint256 i=0; i<userAddress.length; i++){
            Address[arrayId1.length]=data(userAddress[i], amount[i], date[i]);
            arrayId1.push(i);
        }
    }

    function getData(address userAddr) public {
        arrayId2=[0];
        for(uint256 i=0; i<arrayId1.length; i++){
            if(Address[i].userAddress==userAddr){
                getDataByNumber[i]=data1(Address[i].userAddress, Address[i].amount, Address[i].date);
                arrayId2.push(i);
            }
        }
    }

    function viewTotalNumbers() public view returns(uint256) {
        if(arrayId2.length>0){
            return arrayId2.length-1;
        }
        else{
            return 0;
        }
    }
}