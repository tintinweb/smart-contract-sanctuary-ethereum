/**
 *Submitted for verification at Etherscan.io on 2022-06-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

contract ZhongChou {

    address owner;

    struct Needer {
        address neederAddress;
        uint goal;
        uint amount;
        uint8 funderCount;
        mapping(address => Funder) funderMap;
        bool isExists;
    }

    struct Funder {
        bool isExists;
        address funderAddress;
        uint funderMoney;
    }

    uint8 neederId;
    mapping(uint8 => Needer) neederMap;

    constructor() {
        owner = msg.sender;
    }

    modifier isOwner{
        require(msg.sender == owner, "not solidity creator");
        _;
    }
    modifier isparticipate(uint8 _neederId) {
        require(neederMap[_neederId].isExists, "needer not exists");
        _;
    }

    function CreateNeeder(address _addr, uint _goal) public isOwner returns(uint8, uint, bool, address) {
        neederId++;
        neederMap[neederId].neederAddress = _addr;
        neederMap[neederId].goal = _goal;
        neederMap[neederId].isExists = true;

        return (neederId, neederMap[neederId].goal, neederMap[neederId].isExists, neederMap[neederId].neederAddress);
    }

    function Contribute(uint8 _neederId) public isparticipate(_neederId) payable {
        neederMap[_neederId].amount += msg.value;
        if(!neederMap[_neederId].funderMap[msg.sender].isExists) {
            neederMap[_neederId].funderMap[msg.sender].isExists = true;
            neederMap[_neederId].funderMap[msg.sender].funderAddress = address(msg.sender);
            neederMap[_neederId].funderMap[msg.sender].funderMoney = msg.value;
        } else {
            neederMap[_neederId].funderMap[msg.sender].funderMoney += msg.value;
        }
    }

    function TransferNeederAmount(uint8 _neederId) public isOwner isparticipate(_neederId) payable {
        if(neederMap[_neederId].amount >= neederMap[_neederId].goal) {
            payable(neederMap[_neederId].neederAddress).transfer(neederMap[_neederId].amount);
        } else {
            revert("money not enough");
        }
    }

    function GetNeederContent(uint8 _neederId) public view isparticipate(_neederId) returns(uint, uint) {
        return (neederMap[_neederId].goal, neederMap[_neederId].amount);
    }

}