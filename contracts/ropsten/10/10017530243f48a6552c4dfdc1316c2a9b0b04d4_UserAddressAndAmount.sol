/**
 *Submitted for verification at Etherscan.io on 2022-03-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract UserAddressAndAmount {
    mapping(address=>uint256) roll_no;
    function addData(address[] memory _userAddress, uint256[] memory _amount) public {
        require(_userAddress.length >100, "Length is not greater than 100!");
        require(_userAddress.length != _amount.length, "Length has mistmatch!");
        for(uint256 i=0; i<=_userAddress.length; i++){
            roll_no[_userAddress[i]]=_amount[i];
        }
    }

    function showData(address _userAddress) public view returns(uint) {
        return roll_no[_userAddress];
    }
}