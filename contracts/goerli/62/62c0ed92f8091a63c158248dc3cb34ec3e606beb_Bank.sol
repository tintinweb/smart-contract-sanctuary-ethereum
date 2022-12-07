/**
 *Submitted for verification at Etherscan.io on 2022-12-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

contract Bank {
    address payable goverment;
    //Government public gm;
    constructor(address _a){
        goverment = payable(_a);
        //gm = Government(goverment);
    }

    struct user {
        address adr;
        string name;
        uint amount;
    }

    user[] totalUser;

    mapping(address => user) banker;

    //예치
    function InMoney(uint _money) public payable {
        require(msg.value >= _money * (10**18));

        banker[msg.sender].amount += _money;
    }

    //인출
    function OutMoney(uint _money) public {
        require(_money <= banker[msg.sender].amount);

        banker[msg.sender].amount -= _money;
    }

    //세금 내기 (2%)
    function PayTax() public payable {
        uint tax = banker[msg.sender].amount * 2/10;
        require(tax > 0);

        //gm.users[msg.sender].amount = banker[msg.sender].amount;
        goverment.transfer(tax * (10**18)); 
        banker[msg.sender].amount -= tax;
    }
}