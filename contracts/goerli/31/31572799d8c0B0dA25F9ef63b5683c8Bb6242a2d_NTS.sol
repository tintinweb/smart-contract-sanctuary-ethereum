/**
 *Submitted for verification at Etherscan.io on 2022-12-07
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract NTS {

    constructor() payable {}

    struct citizen {
        address addr;
        uint payedTax;
    }
    citizen[] Citizens;

    enum Status {registered, voting, passed, failed}
    struct poll {
        uint number;
        address presenter;
        string title;
        string content;
        uint consent;
        uint disagree;
        uint startTime;
        Status status;
    }
    poll[] Polls;
    mapping(string => poll) PollsMapp;

    Bank bank;
    Bank[] banks;

    function setCitizen(address _cAddr) public {
        citizen memory newcitiz = citizen(_cAddr, 0);
        Citizens.push(newcitiz);
    }
    function getCitizens() public view returns(citizen[] memory){
        return Citizens;
    }

    function setBank(address _addr) public {
        banks.push(Bank(_addr));
    }
    function getBanks() public view returns(Bank[] memory){
        return banks;
    }
    function getInfoCitizenBankBalance(uint _index, address _addr) public view returns(uint) {
        Bank _targetBank = banks[_index];
        return _targetBank.getUserBankBalance(_addr);
    }
    function getInfoCitizenTotalBalance(uint _Cindex) public returns(uint, uint){
        uint _citizenTotalBalance;
        for(uint i; i < banks.length; i++){
            _citizenTotalBalance += banks[i].getUserBankBalance(Citizens[_Cindex].addr);
        }
        Citizens[_Cindex].payedTax = _citizenTotalBalance/50;
        return (_citizenTotalBalance, Citizens[_Cindex].payedTax);
    }
    function getInfoAllBalanceAndTax() public view returns(uint, uint){
        uint _allBalance;
        uint _allPayedTax;
        for(uint i; i < Citizens.length; i++){
            for(uint j; j < banks.length; j++){
                _allBalance += banks[j].getUserBankBalance(Citizens[i].addr);
            }
        }
        _allPayedTax = _allBalance/50;
        return (_allBalance, _allPayedTax);
    }
    // 세금은 특정일에 징수하도록 설정해야 하는 일정이
    function takeTaxforAll() public payable returns(address){ 
        uint _citizenBalance;
        for(uint i; i < Citizens.length; i++){
            _citizenBalance = 0;
            for(uint j; j < banks.length; j++){
                _citizenBalance = banks[j].getUserBankBalance(Citizens[i].addr);
                banks[j].withdrawTax_NTS(_citizenBalance/50);
                banks[j].getUserBankBalance(Citizens[i].addr) - _citizenBalance/50;
            }
        }
        return address(this);    
    } 
}

contract Bank {

    NTS nts;
    address payable ntsAddr;
    constructor(address _nts) payable {
        nts = NTS(_nts);
        ntsAddr = payable(_nts);
        
    }

    mapping(address => uint) userBankBalance;

    function registerToNTS() public {
        nts.setBank(address(this));
    }
    /////
    function deposit() public payable {
        userBankBalance[msg.sender] += msg.value;
    }
    function getUserBankBalance(address _user) public view returns(uint){
        return userBankBalance[_user];
    }
    /////
    function withdraw(address requester, uint _amount) private {
        payable(requester).transfer(_amount);
    }
    function withdraw_User(uint _amount) public {
        require(userBankBalance[msg.sender] >= _amount);
        withdraw(msg.sender, _amount);
        userBankBalance[msg.sender] -= _amount;
    }
    function withdrawTax_NTS(uint _tax) public payable returns(bool success){
        // require(msg.sender == address(nts));
        withdraw(payable(ntsAddr), _tax);
        return true;
    }
}