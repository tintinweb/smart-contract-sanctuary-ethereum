/**
 *Submitted for verification at Etherscan.io on 2022-12-09
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract NTS {  
    receive() external payable {}

    struct citizen {
        address addr;
        uint payedTax;
        uint votingRights;
        // uint[] balanceOfEachBank;// 은행별 예치금
    }
    address[] Citizens;
    mapping(address => citizen) CitizensMap; // 주소와 세금

    Bank bank;
    Bank[] banks;

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
    uint itemIndex;
    string[] PollsArray;
    mapping(string => poll) PollsMapp;

    ////////// CITIZEN SECTION
    function setCitizen() public {
        Citizens.push(msg.sender);

        CitizensMap[msg.sender].addr = msg.sender;
        CitizensMap[msg.sender].payedTax = 0;
        CitizensMap[msg.sender].votingRights = 0;
    }
    function getCitizen(address _cAddr) public view returns(citizen memory){
        return CitizensMap[_cAddr];
    }
    function getCitizens() public view returns(address[] memory){
        return Citizens;
    }
    ////////// BANK SECTION
    function setBank(address _addr) public {
        require(address(Bank(_addr).nts()) == address(this)); // Bank는 컨트렉트형 이라~ bank가 nts 등록할때 
        banks.push(Bank(_addr));
    }
    function getBanks() public view returns(Bank[] memory){
        return banks;
    }
    ////////// GET BALANCE SECTION
    function getABalanceABankACitizen(uint _index, address _cAddr) public view returns(uint) {
        Bank _targetBank = banks[_index];
        return _targetBank.getUserBankBalance(_cAddr);
    }
    function getTotalBalanceACitizen(uint _Cindex) public returns(uint, uint){
        uint _citizenTotalBalance;
        for(uint i; i < banks.length; i++){
            _citizenTotalBalance += banks[i].getUserBankBalance(Citizens[_Cindex]);
        }
        CitizensMap[Citizens[_Cindex]].payedTax = _citizenTotalBalance/50;
        return (_citizenTotalBalance, CitizensMap[Citizens[_Cindex]].payedTax);
    }
    ////////// TAX SECTION
    function takeTaxforAll() public payable returns(bool success){ 
        uint _citizenBalance;
        for(uint i; i < Citizens.length; i++){
            _citizenBalance = 0;
            for(uint j; j < banks.length; j++){
                _citizenBalance = banks[j].getUserBankBalance(Citizens[i]); // 하나의 은행의 한명의 시티즌 잔고
                banks[j].withdrawTax_fromBank(Citizens[i], _citizenBalance/50); // 하나의 은행의 한명의 시티즌 잔고에 2% 택스를 은행에서 이체
                CitizensMap[Citizens[i]].payedTax += _citizenBalance/50; // 하나의 은행의 한명의 시티즌 잔고 deduction
                CitizensMap[Citizens[i]].votingRights += (_citizenBalance/50)/(10**17); // 투표권리 포인트 추가 mapping
            }
        }
        return true;    
    } 
    function getInfoNextTax() public view returns(uint, uint){ // 거둬들일 세금계산
        uint _allBalance; // 모든 시티즌의 잔고 총계 
        uint _allPayedTax; // 세금 총계 
        for(uint i; i < Citizens.length; i++){
            for(uint j; j < banks.length; j++){
                _allBalance += banks[j].getUserBankBalance(Citizens[i]);
            }
        }
        _allPayedTax = _allBalance/50;
        return (_allBalance, _allPayedTax);
    }
    function getAPayedTaxACitizen(address _cAddr) public view returns(uint){
        return CitizensMap[_cAddr].payedTax;
    }
    ////////// 
    function getNtsBalance() public view returns(uint) {
        return address(this).balance;
    }
    ////////// VOTE SECTION
    function setAgenda(string memory _title, string memory _content) public returns(bool success) {
        require(CitizensMap[msg.sender].payedTax >= 10**18*0.25);
        PollsArray.push(_title);
        PollsMapp[_title] = poll(itemIndex + 1, msg.sender, _title, _content, 0, 0, block.timestamp, Status.registered);
        // 안건 등록시 0.25이더를 삭감 
        CitizensMap[msg.sender].payedTax -= 10**18*0.25;
        return true;
    }
    function vote(string memory _title, uint _numberOfVote, bool _consent) public returns(bool success) {
        require(CitizensMap[msg.sender].votingRights >= _numberOfVote, "too many number of Vote as you have");
        require(block.timestamp <= PollsMapp[_title].startTime + 300 seconds, "It's too late, past the voting time."); // 300초면 5분
        if(_consent){
            PollsMapp[_title].consent += _numberOfVote;
        } else {
            PollsMapp[_title].disagree += _numberOfVote;
        }
        CitizensMap[msg.sender].votingRights -= _numberOfVote;
        for(uint i; i < Citizens.length; i++){
            if(Citizens[i] == msg.sender){
                CitizensMap[Citizens[i]].votingRights -= _numberOfVote;
            }
        }
        return true;
    }
    function voteClose(string memory _title) public returns(bool success) {
        require(block.timestamp > PollsMapp[_title].startTime + 5 minutes, "not yet. need more patience");
        if((PollsMapp[_title].consent + PollsMapp[_title].disagree) != 0 && 100 * PollsMapp[_title].consent/(PollsMapp[_title].consent + PollsMapp[_title].disagree) >=60 ){
            PollsMapp[_title].status = Status.passed; // 성공
        } else {
            PollsMapp[_title].status = Status.failed; // 실패 -> 찬성/전체 * 100 < 60 실패
        }
        return true;
    }
    function getAgendas() public view returns(string[] memory){
        return PollsArray;
    }
    function searchAgenda(string memory _title) public view returns(string memory, string memory, uint, uint, Status){
        return (PollsMapp[_title].title, PollsMapp[_title].content, PollsMapp[_title].consent, PollsMapp[_title].disagree, PollsMapp[_title].status);
    }
}

contract Bank {

    NTS public nts;
    constructor(address payable _nts) {
        nts = NTS(_nts);    
    }

    mapping(address => uint) userBankBalance;

    ///// 상부기관에 등록
    function registerToNTS() public {
        nts.setBank(address(this));
    }
    ///// 돈을 넣고
    function deposit() public payable {
        userBankBalance[msg.sender] += msg.value;
    }
    ///// 돈을 빼고
    function withdraw(address requester, uint _amount) private {
        payable(requester).transfer(_amount);
    }
    function withdraw_User(uint _amount) public {
        require(userBankBalance[msg.sender] >= _amount);
        withdraw(msg.sender, _amount);
        userBankBalance[msg.sender] -= _amount;
    }
    function withdrawTax_fromBank(address _cAddr, uint _tax) public payable {
        require(msg.sender == address(nts), "NTS ONLY"); // 세금은 걷는 기관만 실행가능 
        withdraw(address(nts), _tax); // 은행에서 빼가고
        userBankBalance[_cAddr] -= _tax; // 개인계좌에서 차감하고
    }
    ///// 얼마있는지 조회
    function getUserBankBalance(address _userAddr) public view returns(uint){
        return userBankBalance[_userAddr];
    }
}