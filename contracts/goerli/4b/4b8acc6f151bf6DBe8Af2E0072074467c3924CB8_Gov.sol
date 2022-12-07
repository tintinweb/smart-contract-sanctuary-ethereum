/**
 *Submitted for verification at Etherscan.io on 2022-12-07
*/

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