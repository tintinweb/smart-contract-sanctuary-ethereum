/**
 *Submitted for verification at Etherscan.io on 2022-09-10
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.8;


contract SimplePhonebook {
    uint256 public deployTime;

    constructor() {
        deployTime = block.timestamp;
    }

    struct UserStruct {
        uint256 Phonenum;
        address _Address;
        string Name;
    }

    mapping(address => UserStruct) public userAll;
    address[] public userAccounts;

    function addUser(string calldata _Name, address _Address, uint256 _Phonenum) public {
        userAll[_Address] = UserStruct({
            Phonenum: _Phonenum,
            _Address: _Address,
            Name: _Name
        });
    }
    
    function viewUser(address selectaddress) public view returns(UserStruct memory) {
        return userAll[selectaddress];
    }
}