/**
 *Submitted for verification at Etherscan.io on 2022-08-02
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;
contract TestMapping {
    mapping(uint256=>string) phoneNumbers;

    function addItem(uint256 _index, string memory _phoneNumber)external{
        phoneNumbers[_index] = _phoneNumber;
    }


    function getItem(uint256 _index) external view returns(string memory){
        return phoneNumbers[_index];
    }
}