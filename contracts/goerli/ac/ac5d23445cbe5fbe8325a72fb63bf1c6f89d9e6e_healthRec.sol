/**
 *Submitted for verification at Etherscan.io on 2022-10-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract healthRec {
    struct userData{
        address userAddress;
        string name;
        string date;
        string diagnosis;
    }

    mapping(address => userData) internal UserData;

    function inputData(address _yourAddress ,string calldata _name, string calldata _date, string calldata _diagnosis) public {
        UserData[_yourAddress] = userData({
            userAddress: _yourAddress,
            name: _name,
            date: _date,
            diagnosis: _diagnosis
        });
    }

    function viewDetails(address _yourAddress) public view returns(userData memory) {
        require(msg.sender == UserData[_yourAddress].userAddress, "You are not the owner of this data");
        return UserData[_yourAddress];
    }
}