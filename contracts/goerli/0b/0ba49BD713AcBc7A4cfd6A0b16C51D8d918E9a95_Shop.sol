/**
 *Submitted for verification at Etherscan.io on 2023-06-01
*/

//SPDX-License-Identifier: Unlicense
pragma solidity = 0.8.15;

contract Shop {
    mapping(address => uint256) private accountBalance;
    mapping(address => string) private accountName;
    address[] public account;

    function createAccount(string memory name) public {
        require(bytes(name).length > 0 ,"Error name = 0");
        require(bytes(accountName[msg.sender]).length ==0, "Error already have account");
        accountName[msg.sender]=name;
    }

    function isAccount(address _account) public view returns (bool) {
        if (bytes(accountName[_account]).length>0) {
            return true;
        } 
        return false;
    }

    function getAccountName(address _account) public view returns (string memory){
        return accountName[_account];
    }

    function deposit() public payable{
        require(bytes(accountName[msg.sender]).length >0 ,"Error : Account not register");
        accountBalance[msg.sender] += msg.value;
    }

    function withdraw(uint256 _amount) public {
        require(accountBalance[msg.sender] > 0, "Error: Insufficient balance");
        require(accountBalance[msg.sender] >= _amount,"Error input");
        accountBalance[msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount);
    }
    
    function transferTo(address _to, uint256 _amount) public {
        require(_amount > 0);
        require(accountBalance[msg.sender] >= _amount);
        accountBalance[msg.sender] -= _amount;
        accountBalance[_to] += _amount;
    }

    function balanceOf(address _account) public view returns (uint256) {
        return accountBalance[_account];
    }

    function checkBalance() public view returns (uint256) {
    return address(this).balance;
    }

    function deleteAccount() public {
        require(bytes(accountName[msg.sender]).length > 0, "Error Account not register");
        if(accountBalance[msg.sender] > 0){
            withdraw(accountBalance[msg.sender]);
        }
        delete accountName[msg.sender];
    }

}