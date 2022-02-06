// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./multiOwnable.sol";
import "./futureCoin.sol";

contract ethBridge is Multiownable {
    FUTURECOIN private token;

    // GasPrice * GasLimit
    uint256 public minimumCommissionGas;

    // Minimum amount of tokens that can be exchanged on bridge
    uint256 public minimumExchangeOnBridge;

    mapping(address => uint256) public tokensSent;
    mapping(address => uint256) public tokensRecieved;
    mapping(address => uint256) public tokensRecievedButNotSent;

    mapping(address => uint256) public howManyWritesToRefund;
 
    address public tokenAddress; 

    constructor (address payable _token, uint256 _minimumCommissionGas, uint256 _minimumExchangeOnBridge) {
        tokenAddress = _token;
        token = FUTURECOIN(_token);
        minimumCommissionGas = _minimumCommissionGas;
        minimumExchangeOnBridge = _minimumExchangeOnBridge;
    }
 
    bool transferStatus;
    
    bool avoidReentrancy = false;
 
    function sendTokens(uint256 amount) public {
        require(msg.sender != address(0), "Zero account");
        require(amount >= minimumExchangeOnBridge,"Amount of tokens should be more then minimumExchangeOnBridge");
        require(token.balanceOf(msg.sender) >= amount,"Not enough balance");
        
        transferStatus = token.transferFrom(msg.sender, address(this), amount);
        if (transferStatus == true) {
            tokensRecieved[msg.sender] += amount;
        }
    }
 
    function writeTransaction(address user, uint256 amount) public onlyAllOwners {
        require(user != address(0), "Zero account");
        require(amount > 0,"Amount of tokens should be more then 0");
        require(!avoidReentrancy);

        uint256 availableAmountToSent = tokensRecievedButNotSent[user] - tokensSent[user];
        require(amount <= availableAmountToSent, "You cannot approve more than the user has contributed");
        
        avoidReentrancy = true;
        tokensRecievedButNotSent[user] += amount;
        howManyWritesToRefund[user] += 1;
        avoidReentrancy = false;
    }

    function recieveTokens(uint256[] memory commissions) public payable {
        if (tokensRecievedButNotSent[msg.sender] != 0) {
            require(commissions.length == owners.length, "The number of commissions and owners does not match");
            uint256 sum;
            for(uint i = 0; i < commissions.length; i++) {
                sum += commissions[i];
            }
            require(msg.value >= sum, "Not enough ETH (The amount of ETH is less than the amount of commissions.)");
            require(msg.value >= howManyWritesToRefund[msg.sender] * owners.length * minimumCommissionGas, "Not enough ETH (The amount of ETH is less than the internal commission.)");
        
            for (uint i = 0; i < owners.length; i++) {
                address payable owner = payable(owners[i]);
                uint256 commission = commissions[i];
                owner.transfer(commission);
            }

            uint256 amountToSent;

            amountToSent = tokensRecievedButNotSent[msg.sender] - tokensSent[msg.sender];
            transferStatus = token.transfer(msg.sender, amountToSent);
            if (transferStatus == true) {
                tokensSent[msg.sender] += amountToSent;
                howManyWritesToRefund[msg.sender] = 0;
            }
        }
    }
 
    function withdrawTokens(uint256 amount, address reciever) public onlyAllOwners {
        require(amount > 0,"Amount of tokens should be more then 0");
        require(reciever != address(0), "Zero account");
        require(token.balanceOf(address(this)) >= amount,"Not enough balance");
        
        token.transfer(reciever, amount);
    }
    
    function withdrawEther(uint256 amount, address payable reciever) public onlyAllOwners {
        require(amount > 0,"Amount of tokens should be more then 0");
        require(reciever != address(0), "Zero account");
        require(address(this).balance >= amount,"Not enough balance");

        reciever.transfer(amount);
    }

    function setMinimumCommissionGas(uint256 gasPrice, uint256 gasLimit) public onlyAnyOwner {
        uint256 commission = gasPrice * gasLimit;
        minimumCommissionGas = commission;
    }

    function setMinimumExchangeOnBridge(uint256 _minimumExchangeOnBridge) public onlyAnyOwner {
        minimumExchangeOnBridge = _minimumExchangeOnBridge;
    }

    function setHowManyWritesToRefund(uint256 amount, address user) public onlyAllOwners {
        howManyWritesToRefund[user] = amount;
    }
}