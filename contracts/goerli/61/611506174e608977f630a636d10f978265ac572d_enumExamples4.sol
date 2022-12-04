/**
 *Submitted for verification at Etherscan.io on 2022-12-04
*/

// SPDX-License-Identifier: GPL-3.0
// 20221130

pragma solidity >=0.7.0 <0.9.0;

contract enumExamples4 {
    enum Status{available, lended, recovery, missed} // reserved는 제외

    struct Book {
        uint number;
        string title;
        address lender;
        address[] waitlist;
        Status status;
    }
    mapping(string => Book) Books;

    struct User {
        string name;
        address addr;
        uint borrowed;
        uint miss_count;
    }
    mapping(address => User) Users;

    uint index=1;

    // 책 정보 넣기
    function setBook(string memory _title) public {
        Books[_title] = Book(index++, _title, address(0), new address[](0), Status.available); // address[] default
    }

    // 책 정보 받아오기
    function getBook(string memory _title) public view returns(uint, string memory, address, address[] memory, Status) {
        return (Books[_title].number, Books[_title].title, Books[_title].lender, Books[_title].waitlist, Books[_title].status);
    }

    function setUser(string memory _name) public {
        Users[msg.sender] = User(_name, msg.sender, 0, 0);
    }

    function getUser(address _addr) public view returns(User memory){
        return Users[_addr];
    }

    // 책 빌리기
    function lendBook(string memory _title) public {
        // 책을 빌리려고 하면 어떤 상황이어야 하는가?
        require(Users[msg.sender].miss_count <= 3 && Books[_title].status == Status.available );
        Books[_title].status = Status.lended; // 상태 변화
        Books[_title].lender = msg.sender; // 대출자 적용
        Users[msg.sender].borrowed++;
        // 예약자가 있는지 확인? 필수? 
    }

    //반납후 최우선 예약자에게 자동 대출
    function autoLendging(string memory _title) public {
        require(Books[_title].status == Status.available);
        if(Books[_title].waitlist.length > 0) {
            Books[_title].lender = Books[_title].waitlist[0];
            Users[Books[_title].waitlist[0]].borrowed++;

            for(uint i; i < Books[_title].waitlist.length - 1 ; i++) {
                Books[_title].waitlist[i]  = Books[_title].waitlist[i+1];
            }

            Books[_title].waitlist.pop();
            Books[_title].status = Status.lended;
        }
    }

    // 반납
    function returnBook(string memory _title) public {
        require(msg.sender == Books[_title].lender);
        Books[_title].status = Status.available;
        Books[_title].lender = address(0);
        Users[msg.sender].borrowed --;
        // 예약자 있는지 확인?
        autoLendging(_title);
    }

    // 분실신고
    function reportMissing(string memory _title) public {
        // 대출한 사람만 가능하도록
        require(Books[_title].lender == msg.sender);
        Books[_title].status = Status.missed;
        // miss_count 올리기
        Users[msg.sender].miss_count ++;
    }

    //예약
    function reserveBook(string memory _title) public {
        require(Books[_title].status == Status.lended && Books[_title].waitlist.length < 3);
        // waitlist에 현재 msg.sender가 추가됨
        Books[_title].waitlist.push(msg.sender); 
    }
}