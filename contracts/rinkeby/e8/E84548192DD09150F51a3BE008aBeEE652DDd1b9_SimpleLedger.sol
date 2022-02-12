/**
 *Submitted for verification at Etherscan.io on 2022-02-12
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract SimpleLedger {
    // State/DB 
    string public name;
    uint public totalBalance;
    address[] public accounts;
    mapping(address => uint) public balances;

    struct AccountBalance {
        address addr;
        uint balance;
    }

    // Deploy function
    constructor(string memory _name) {
        name = _name;
    }

    function deposit(address _from, uint _amount) public {
        if (_amount == 0){
            revert("Amount is less than zero");
        }

        if (balances[_from] == 0){
            accounts.push(msg.sender);
        }

        balances[msg.sender] += _amount;
        totalBalance += _amount;
    }

    function withdraw(address _from, uint _amount) public {
        if (_amount >= balances[_from]){
            accounts.push(msg.sender);

            balances[msg.sender] -= _amount;
            totalBalance -= _amount;
        }
        else {
            revert("No money");
        }
    }

    function balanceOf(address addr) public view returns (uint) {
        return balances[addr];
    }

    function getAllAccount() public view returns (AccountBalance[] memory) {
        AccountBalance[] memory accountBalances = new AccountBalance[](accounts.length);
        for(uint index = 0; index < accounts.length; index++){
            address addr = accounts[index];
            uint balance = balances[addr];
            accountBalances[index] = AccountBalance(addr, balance);
        }
        return accountBalances;
    }
}