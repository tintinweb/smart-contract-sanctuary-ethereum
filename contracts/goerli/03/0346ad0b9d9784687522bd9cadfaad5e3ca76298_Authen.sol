/**
 *Submitted for verification at Etherscan.io on 2022-10-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Authen{

    struct Owner {
        address addr;
        string name;
    }

    mapping(address => Owner) user;

    //create data function
    function create(address _address,string memory _name) public {
        require(user[_address].addr != msg.sender);
        user[_address].addr = _address;
        user[_address].name = _name;
    }

    //ReportData
    function reportData(address _address) public view returns(string memory name){
        require(_address == msg.sender,"Unauthorized");
        return (user[_address].name);
    }

}