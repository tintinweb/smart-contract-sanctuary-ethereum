/**
 *Submitted for verification at Etherscan.io on 2022-11-14
*/

//Create a smart contract to help a landlord receive rent from his tenant
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract GetRent {
    address payable public landlord;
    uint256 rent; 

    constructor()
    {
        landlord=payable(msg.sender);
    }

    function rentAmount(uint256 _rent) external
    {   require(msg.sender==landlord,"only the landlord can call this method.");
        rent = _rent;
    }
    function displayRent() public view returns(uint256)
    {
        return rent;        //tenant can view the amount of rent specified by landlord
    }

    function deposit(uint _rent) public payable {
        require(msg.value == _rent);        //tenant can deposite required amount
    }

    function withdraw(uint _amount)external
    {
        require(msg.sender==landlord,"only the landlord can call this method.");
        payable(msg.sender).transfer(_amount);
    }

    function getBalance() external view returns (uint)
    {
        return address(this).balance;
    }

}