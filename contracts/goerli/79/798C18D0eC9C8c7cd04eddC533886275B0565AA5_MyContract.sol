/**
 *Submitted for verification at Etherscan.io on 2022-10-29
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
contract MyContract{


string _tonnage;
string _lNum;
string _survey;
string _subdist;
string _titlenum;
string _district;
string _city;
string _name;
string _address;
string _size;

constructor (string memory tonnage, string memory lNum, string memory survey, string memory subdist, string memory titlenum, string memory district, string memory city, string memory name, string memory laddress, string memory size) {
    _tonnage = tonnage;
    _lNum = lNum;
    _survey = survey;
    _subdist = subdist;
    _titlenum = titlenum;
    _district = district;
    _city = city;
    _name = name;
    _address = laddress;
    _size = size;
}

function storeTonnage(string memory tonnage)public {
    _tonnage = tonnage;
}
function storeLnum(string memory lNum)public {
    _lNum = lNum;
}
function storeSurvey(string memory survey)public {
    _survey = survey;
}
function storeSubdist(string memory subdist)public {
    _subdist = subdist;
}
function storeTitlenum(string memory titlenum)public {
    _titlenum = titlenum;
}
function storeDistrict(string memory district)public {
    _district = district;
}
function storeCity(string memory city)public {
    _city = city;
}
function storeName(string memory name)public {
    _name = name;
}
function storeAddress(string memory laddress)public {
    _address = laddress;
}
function storeSize(string memory size)public {
    _size = size;
}

function store1(string memory tonnage, string memory lNum, string memory survey, string memory subdist, string memory titlenum, string memory district, string memory city, string memory name, string memory laddress, string memory size) public {

    
    _tonnage = tonnage;
    _lNum = lNum;
    _survey = survey;
    _subdist = subdist;
    _titlenum = titlenum;
    _district = district;
    _city = city;
    _name = name;
    _address = laddress;
    _size = size;
    }


function retrieveTonnage() public view returns (string memory){
        return _tonnage;
}
function retrieveLnum() public view returns (string memory){
        return _lNum;
}
function retrieveSurvey() public view returns (string memory){
        return _survey;
}
function retrieveSubdist() public view returns (string memory){
        return _subdist;
}
function retrieveTitlenum() public view returns (string memory){
        return _titlenum;
}
function retrieveDist() public view returns (string memory){
        return _district;
}
function retrieveCity() public view returns (string memory){
        return _city;
}
function retrieveName() public view returns (string memory){
        return _name;
}
function retrieveAddress() public view returns (string memory){
        return _address;
}
function retrieveSize() public view returns (string memory){
        return _size;
}

}