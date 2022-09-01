//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "AppStorage.sol";


contract ticket{

 Account internal ac;
 Ticket internal t;
 Accounts internal  a;

     function getAccountN() external  view returns(uint ) {
       
        return  ac.accNo;
    }


    function setTicketNum(uint _num) external {

        t.ticketNo=_num;
    }

    function getTicketNum() external  view  returns(uint){

        return t.ticketNo;
    }

    function setTicketNumber(uint _num) external {
       
        t.ticketNo=_num;
    }

    function getTicketNumber() external  view  returns(uint){

        return t.ticketNo;
    }

    function setAccountNoFromTicket(uint _no) external {
        
        a.accNo = _no ;
    }

    function getAccountFromTicket() external  view  returns(uint) {
        
       return  a.accNo  ;
    }


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct Account {

    uint accNo;

}

struct Accounts {

    uint accNo;

}

struct Ticket {

    uint ticketNo;
    uint ticketNumber;
}

struct AppStorage {

    uint appNo;
}