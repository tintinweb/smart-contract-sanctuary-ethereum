/**
 *Submitted for verification at Etherscan.io on 2022-05-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

/*
Deposit specified tokens. Map address to token amount. Institute a lock period
Withdraw tokens after a certain period of time
Automagically transfer a certain percentage of tokens to the FTX account
FTX will automatically send money back after a set period of time
*/

contract EgoManagedTradingSystem {
    mapping (address => uint) private balances;
    address payable tradeBotAddress = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    
    address public owner;

    // Events
    event LogDepositMade(address accountAddress, uint amount);
    event LogWithdrawalMade(address accountAddress);
    event TradeBotDeposit(address tradeBotAddress, uint amount);

    //Constructor
    constructor() public {
        owner = msg.sender;
         //Add this later
    }

    modifier onlyOwner {
        require(
            msg.sender == owner,
            "caller is not the owner"
        );
        _;
    }

    function deposit() public payable returns (uint) {
        require((balances[msg.sender] + msg.value) >= balances[msg.sender]);

        balances[msg.sender] += msg.value;

        emit LogDepositMade(msg.sender, msg.value);

        return balances[msg.sender];
    }

    function withdrawal(uint withdrawAmount) public returns (uint remainingBal) {
        require(withdrawAmount <= balances[msg.sender]);

        balances[msg.sender] -= withdrawAmount;
        msg.sender.transfer(withdrawAmount);

        emit LogWithdrawalMade(msg.sender);

        return balances[msg.sender];
    }

    function balance() public view returns (uint) {
        return balances[msg.sender];
    }

    function autoTradeBotDeposit() public payable {
        //automatically transfer funding to the tradeBot
        uint totalBalance = address(this).balance;
        uint _amount = totalBalance * 1/10;

        tradeBotAddress.transfer(_amount); 
        emit TradeBotDeposit(tradeBotAddress, _amount);
    }

    function manualTradeBotDeposit(uint _amount) public payable onlyOwner {
        tradeBotAddress.transfer(_amount);  
        emit TradeBotDeposit(tradeBotAddress, _amount);
    } 

}