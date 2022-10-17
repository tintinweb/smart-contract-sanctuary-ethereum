/**
 *Submitted for verification at Etherscan.io on 2022-10-17
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract insurance{

string _insurer;
string _insured;
string _beneficiary;
string _com_name;
uint _amount;
uint _pricePerEach;

constructor (string memory insurer, string memory insured, string memory beneficiary, string memory com_name, uint pricePerEach, uint amount){
    _insurer = insurer;
    _insured = insured;
    _beneficiary = beneficiary;
    _com_name = com_name;
    _pricePerEach = pricePerEach;
    _amount = amount;
}

function setInsurer(string memory insurer) public{
    _insurer = insurer;
}

function setInsured(string memory insured) public{
    _insured = insured;
}

function setBeneficiary(string memory beneficiary) public{
    _beneficiary = beneficiary;
}

function setCompanyName(string memory com_name) public{
    _com_name = com_name;
}

function setPricePerEach(uint pricePerEach) public{
    _pricePerEach = pricePerEach;
}

function setAmount(uint amount) public{
    _amount = amount;
}

function getInsurer() public view returns(string memory){
    return _insurer;
}

function getInsured() public view returns(string memory){
    return _insured;
}

function getbeneficiary() public view returns(string memory){
    return _beneficiary;
}

function getCompanyName() public view returns(string memory){
    return _com_name;
}

function gerPricePerEach() public view returns(uint){
    return _pricePerEach;
}

function getamount() public view returns(uint){
    return _amount;
}

function setAllData(string memory insurer, string memory insured, string memory beneficiary, string memory com_name, uint pricePerEach, uint amount) public{
    _insurer = insurer;
    _insured = insured;
    _beneficiary = beneficiary;
    _com_name = com_name;
    _pricePerEach = pricePerEach;
    _amount = amount;
}

}