/**
 *Submitted for verification at Etherscan.io on 2022-03-14
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract ContributeManage{
    struct operator{
        string name;
        bool canOperate;
    }
    address owner;
    mapping(address=>operator) operators;
    uint8 operatorNum = 0;
    mapping(string=>uint) contributionRecord;
    constructor() {
        owner = msg.sender;
    }
    modifier onlyOwner{
        require(owner == msg.sender);
        _;
    }
    modifier onlyOperator(){
        require(operators[msg.sender].canOperate);
        _;
    }


    function setOperator(address operatorAddress,string memory name) public onlyOwner{
        operators[operatorAddress].name = name;
        operators[operatorAddress].canOperate = true;
        operatorNum += 1;
    }
    function getOperatorNum() public view returns(uint8) {
        return operatorNum;
    }
    function getOperatorInfo(address OperatorAddress) public view returns(operator memory) {
        operator memory tmp = operators[OperatorAddress];
        return tmp;
    }
    function banOperator(address operatorAddress) public onlyOwner{
        operators[operatorAddress].canOperate = false;
    }
    function addContribution(string memory name,uint score) public onlyOperator{
        contributionRecord[name] += score;
    }
    function getContribution(string memory name) public view returns(uint){
        return contributionRecord[name];
    }
    function modifyContribution(string memory name,uint score) public onlyOwner{
        contributionRecord[name] = score;
    }
    
}