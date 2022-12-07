/**
 *Submitted for verification at Etherscan.io on 2022-12-07
*/

// File: test11.sol

pragma solidity ^0.8.0;

contract Bank {

    struct User {
        string name;
        uint amount;
    }    
    mapping(address => User) Users;

    // 정부기관 등록
    Gov public gov;

    // 은행 개설시 정부기관 연동
    constructor(address _govAddress) {
        gov = Gov(_govAddress);
    }

    // 계좌개설
    function create(string memory _name) public {
        //require user 없을때만
        Users[msg.sender].name = _name;
        //todo 신규입금
    }

    // 입금
    function deposit() public payable {
        // 시민
        address user = payable(msg.sender);
        // 은행계좌
        Users[msg.sender].amount = (msg.value / (10**18)*98/100);
        // 세금계산
        uint taxAmount = msg.value/(10**18)*2/100;

        // address bank = payable(this);
        // 세금납부
        gov.reportTax(msg.sender, taxAmount);
        
    }

    function checkMyAccount() public view returns(string memory, uint) {
        return(Users[msg.sender].name, Users[msg.sender].amount);
    }

    

}

//정부
contract Gov {

    // 상태
    enum Status{enroll, voting, pass, fail}
    // 안건
    struct Agenda {
        uint no;
        string name;
        string title;
        string content;
        uint rate;
        Status status;
    }

    mapping(string => Agenda) Agendas;

    // 세금관리 구조체
    struct User {
        // string name;
        uint amount;
    }

    // 유저
    mapping(address => User) Users;

    //세금납부 - 은행에서만 
    function reportTax(address _user, uint _taxAmount) external {
        Users[_user].amount = _taxAmount;
    }

    function registAgenda(string memory _title, string memory _content) public {
        require (Users[msg.sender].amount > 1);
        // Agendas[]
        
        

    }

    

}