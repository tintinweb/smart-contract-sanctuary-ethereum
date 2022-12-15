/**
 *Submitted for verification at Etherscan.io on 2022-12-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LuckyDraw {
    mapping (address => uint256) public balances;
    mapping (address => string) public mappingAcctName;
    // string[] public accountNameList;
    address[] public accounts;
    address public admin;

    constructor() {
        admin = msg.sender;
    }

    function register(string memory accountName) public payable {
        require(msg.value == 0.001 ether, "Register sizes are restricted to 0.001 ether");
        require(balances[msg.sender] == 0, "An address cannot register twice");
        accounts.push(msg.sender);
        require(accounts.length <= 6, "Can't register more than 6");
        // accountNameList.push(accountName);
        balances[msg.sender] = msg.value;
        mappingAcctName[msg.sender] = accountName;
    }

    function userCount() public view returns (uint256 count) {
        count = accounts.length;
    }

    function adminTransfer(uint256 accIndex, uint256 amount) public 
    {
        require(msg.sender == admin, "You're not authorized!");
        require(amount <= address(this).balance, "withdraw amount exceed");
        address account = accounts[accIndex];
        payable(account).transfer(amount);
    }

    function adminReset() public
    {
        require(msg.sender == admin, "You're not authorized!");
        require(address(this).balance == 0, "Can't reset because balance more than 0");
        for (uint256 i = 0; i < accounts.length; i++) {
            address account = accounts[i];
            balances[account] = 0;
            mappingAcctName[account] = '';
        }
        delete accounts;
        // delete accountNameList;
    }

    function removeAccount(uint256 accIndex) public {
        require(msg.sender == admin, "You're not authorized!");
        address account = accounts[accIndex];
        payable(account).transfer(balances[account]);
        balances[account] = 0;
        mappingAcctName[account] = '';
        // accountNameList[accIndex] = accountNameList[accountNameList.length - 1];
        // accountNameList.pop();
        accounts[accIndex] = accounts[accounts.length - 1];
        accounts.pop();
    }
}