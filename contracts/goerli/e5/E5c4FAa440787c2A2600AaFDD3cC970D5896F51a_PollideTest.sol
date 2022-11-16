// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract PollideTest {
    struct User{
        string id;
        string name;
        ResultInfo[] result;
    }
    struct ResultInfo {
        uint256 date;
        bool result;
    }
    mapping(address => User) public user;
    address public tempaddress = 0xCda26c368d585729EEDFb86C2DA6C7d302242b9d;

    constructor() {
        user[tempaddress].id = "12345";
        user[tempaddress].name = "tom";
        user[tempaddress].result.push(ResultInfo(12412,true));
        user[tempaddress].result.push(ResultInfo(23534,false));
        user[tempaddress].result.push(ResultInfo(679,true));

    }

    function getUserInfo() public view returns (User memory){
        return user[tempaddress];
    }

    function getUserResults() public view returns (ResultInfo[] memory){
        return user[tempaddress].result;
    }


}