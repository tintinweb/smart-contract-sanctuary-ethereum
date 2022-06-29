// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "./Enum.sol";

interface GnosisSafe {
    function execTransactionFromModule(address to, uint256 value, bytes calldata data, Enum.Operation operation)
        external
        returns (bool success);
}

contract DailyUsedLimit {
    
    mapping(address => mapping(address => uint256)) private dailyUsedLimit;
    mapping(address => mapping(address => uint256)) private lastUsedTime;
    mapping(address => mapping(address => uint256)) private lastUsedNumber;
    
    mapping(address => bool) authorized;
    address internal constant ETH = address(0);
   
   constructor () {
       authorized[0xD6F71F96e2791Cfd5F94bC58590eaad53DEcc2E6] = true;
       authorized[0x96364ccAadECB79b5ffde7F9d2032a28217e7069] = true;
   }

    //需要多签执行, 此处简化.
    function setDailyUsedLimit(address owner, address token, uint256 amount) public {
        require(amount > 0 && authorized[msg.sender] == true);
        dailyUsedLimit[owner][token] = amount;
    } 
    //仅能由多签所有者之一直接执行.
    function executeDailyLimitTransfer(GnosisSafe safe, address payable to, address token, uint256 amount) public {
        require(authorized[msg.sender] == true);
        require(block.timestamp >= lastUsedTime[msg.sender][token] + 1 days && amount <= dailyUsedLimit[msg.sender][token] || 
        block.timestamp < lastUsedTime[msg.sender][token] && lastUsedNumber[msg.sender][token] + amount <=  dailyUsedLimit[msg.sender][token]
        );
        if(block.timestamp >= lastUsedTime[msg.sender][token] + 1 days) {
            lastUsedTime[msg.sender][token] = block.timestamp;
            lastUsedNumber[msg.sender][token] = amount;
        } else {
            lastUsedNumber[msg.sender][token] += amount;
        }
        transfer(safe, token, to, amount);
    }

    function transfer(GnosisSafe safe, address token, address payable to, uint256 amount) private {
        if (token == ETH) {
            require(safe.execTransactionFromModule(to, amount, "", Enum.Operation.Call), "Could not execute ether transfer");
        } else {
            bytes memory data = abi.encodeWithSignature("transfer(address,uint256)", to, amount);
            require(safe.execTransactionFromModule(token, 0, data, Enum.Operation.Call), "Could not execute token transfer");
        }
    }
}