//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "AppStorage.sol";


contract ticket{

 Account internal ac;
ERC721Storage internal e;



    function init (string memory name_, string memory symbol_) external{
        e._name = name_;
        e._symbol = symbol_;
       
    }

    function setIncvalue() external {

        e.tokenLastID++;
    }


  function setAccountNobyt(uint _no) external {
       
        ac.accNo = _no ;
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


//----------DEVELOPMENT READY--------------

struct ERC721Storage{

    // Token name
    string  _name;

    // Token symbol
    string  _symbol;

    // Token Last ID

    uint tokenLastID;

    address tickeContract;

    // // Mapping from token ID to owner address
    // mapping(uint256 => address)  _owners;

    // // Mapping owner address to token count
    // mapping(address => uint256)  _balances;

    // // Mapping from token ID to approved address
    // mapping(uint256 => address)  _tokenApprovals;

    // // Mapping from owner to operator approvals
    // mapping(address => mapping(address => bool))  _operatorApprovals;

}