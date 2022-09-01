/**
 *Submitted for verification at Etherscan.io on 2022-09-01
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

struct order{
    bool moneyCheck;
    bool sendAction;
    uint value;
}

contract Garant{
    mapping(address => mapping( address => order)) public transactionList; //change to private
    address public admin; //change to private
    uint public hold;

    constructor(){
        admin = msg.sender;
    }

    modifier dealExist(address buyer) {
        require(transactionList[buyer][msg.sender].value != 0, "Deal does not exist");
        _;
    }

    modifier moneyConfimWith(address buyer){
        require(transactionList[buyer][msg.sender].moneyCheck == true, "Money not confim");
        _;
    }

    modifier sendConfim(address toSeller){
        require(transactionList[msg.sender][toSeller].moneyCheck == true, "Send not confim");
        _;
    }

    // call by buyer
    function transferTo(address to) external payable{
        if(transactionList[msg.sender][to].value == 0) {
            transactionList[msg.sender][to].moneyCheck = false;
            transactionList[msg.sender][to].sendAction = false;
        }
        transactionList[msg.sender][to].value += msg.value;
    }

    // call by seller
    function moneyForMeFrom(address buyer) external view returns (uint){
        return transactionList[buyer][msg.sender].value;
    }

    // call by seller
    function moneyForMeConfim(address buyer) external dealExist(buyer){
        transactionList[buyer][msg.sender].moneyCheck = true;
    }

    // call by seller
    function moneyForMeCancel(address buyer) external dealExist(buyer){
        payable(buyer).transfer(transactionList[buyer][msg.sender].value);
        delete transactionList[buyer][msg.sender];
    }

    // call by seller
    function sendActionConfim(address buyer) external moneyConfimWith(buyer){
        transactionList[buyer][msg.sender].moneyCheck = true;
    }

    // call by buyer
    function getBoxConfim(address seller) external sendConfim(seller){
        uint tmp = transactionList[msg.sender][seller].value / 1000 * 25;
        hold += tmp;
        payable(seller).transfer(transactionList[msg.sender][seller].value - tmp);
        delete transactionList[msg.sender][seller];
    }

    // call by buyer
    function getBoxCancel(address seller) external sendConfim(seller){
        payable(msg.sender).transfer(transactionList[msg.sender][seller].value);
    }

    function getBalance() external view returns(uint){
        return address(this).balance;
    }

    function sendToAdmin() external{
        payable(admin).transfer(hold);
        hold = 0;
    }

}