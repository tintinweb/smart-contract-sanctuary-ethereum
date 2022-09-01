//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "AppStorage.sol";


contract ticket{

 Account internal ac;
 Ticket internal t;

     function getAccountN() external  view returns(uint ) {
       
        return  ac.accNo;
    }


    function setTicketNum(uint _num) external {

        t.ticketNo=_num;
    }

    function getTicketNum() external  view  returns(uint){

        return t.ticketNo;
    }

    function setAccountNoFromTicket(uint _no) external {
       
        ac.accNo = _no ;
    }


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct Account {

    uint accNo;

}

struct Ticket {

    uint ticketNo;
}

struct AppStorage {

    uint appNo;
}