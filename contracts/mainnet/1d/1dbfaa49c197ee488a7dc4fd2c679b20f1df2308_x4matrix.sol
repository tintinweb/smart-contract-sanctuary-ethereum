/**
 *Submitted for verification at Etherscan.io on 2022-08-18
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

contract x4matrix {
    address private treasury;
    uint public price;

    constructor(uint _price, address _treasury){
        price=_price;
        treasury=_treasury;
        members[treasury].isActive=true;
        members[treasury].upline=treasury;
    }

    struct member{
        uint numOfGrandDownlines;
        address upline;
        bool isActive;
    }

    mapping (address=>member) public members;

    event newMember(address _adress, address referrer);
    function _registerMember(address referrer) private{
        require (msg.value==price);
        require (members[referrer].isActive==true);
        require(members[msg.sender].isActive==false);
        members[msg.sender].isActive=true;
        members[msg.sender].upline=referrer;
        handOutDivident(members[referrer].upline);
        emit newMember(msg.sender, referrer);
    }

    function handOutDivident(address person) private {
        members[person].numOfGrandDownlines++;
        if(members[person].numOfGrandDownlines%4==0) payable(treasury).transfer(price);
        else payable(person).transfer(price);
    }

    function register(address referrer) external payable {
        _registerMember(referrer);
    }

    function register() external payable {
        _registerMember(treasury);
    }

    function changeTreasury(address newTreasury) external {
        require(msg.sender==treasury);
        treasury=newTreasury;
    }

    fallback() external payable {
        _registerMember(treasury);
    }
}