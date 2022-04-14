pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

contract TestContract {
    
    struct Account {
    uint balance;
    uint dailylimit;
}
    Account my_account = Account(0, 10); 

    function setBalance(uint new_balance) public returns (uint, uint) {
    my_account.balance = new_balance;
    return (my_account.balance, my_account.dailylimit);
}
    
    receive() external payable{}

    fallback() external payable {}
}