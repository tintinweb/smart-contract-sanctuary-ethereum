//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC20} from "./IERC20.sol";
import {Ownable} from "./Ownable.sol";

contract SwapTokens is Ownable {
    
    address public tokenFrom;
    address public tokenTo;
    
    uint256 public tokenFromTotal;
    uint256 public tokenToTotal;
    
    address[] public swapUsers;
    mapping(address => uint256) public swappedAmount;
    
    bool public isInitiated = false;
    
    bool public isTaxEnabled = true;
    address public taxReceiver;
    
    uint256 public taxStart;
    uint256 public dailyTaxRate = 1;
    

    constructor(address _tokenFrom, address _tokenTo, uint256 _tokenFromTotal, uint256 _tokenToTotal, address _taxReceiver, uint256 taxOffsetDays) {
        tokenFrom = _tokenFrom;
        tokenTo = _tokenTo;
        tokenFromTotal = _tokenFromTotal;
        tokenToTotal = _tokenToTotal;
        taxStart = block.timestamp - (taxOffsetDays*24*60*60);
        taxReceiver = _taxReceiver;
    }
   
    
    function swapTokens(uint256 _amount) public {
        require(_amount > 0, "amount cannot be 0");
        require(isInitiated == true, "Swap has not started yet");
        
        IERC20(tokenFrom).transferFrom(msg.sender, address(this), _amount);
        
        uint256 totalAmount = ((_amount * tokenToTotal) / tokenFromTotal);
        uint256 userAmount = totalAmount;
        
        // 50 days
        if(isTaxEnabled && taxRate() > 0) {
            uint256 taxAmount = ((totalAmount * taxRate()) / 100);
            userAmount = userAmount - (taxAmount);
            
            IERC20(tokenTo).transfer(taxReceiver, taxAmount);
        }
        
        IERC20(tokenTo).transfer(msg.sender, userAmount);
        
        if(swappedAmount[msg.sender] <= 0) {
            swapUsers.push(msg.sender);
        }
        swappedAmount[msg.sender] = swappedAmount[msg.sender] + (totalAmount);
    }
    
    function calculateTokens(uint256 _amount) public view returns(uint256) {
        uint256 receiveAmount = ((_amount * tokenToTotal) / tokenFromTotal);
        if(isTaxEnabled && taxRate() > 0) {
            uint256 taxAmount = ((receiveAmount * taxRate()) / 100);
            receiveAmount = receiveAmount - (taxAmount);
        }
        return receiveAmount;
    }
    
    function taxRate() public view returns(uint256) {
        uint256 daysPassed = (((block.timestamp - taxStart)) / 24*60*60);
        uint256 calculatedTaxRate = 0;
        if(daysPassed < taxPeriod()) {
            calculatedTaxRate = ((uint256(100) - (daysPassed) * dailyTaxRate));
        }
        return calculatedTaxRate;
    }
    
    function daysRunning() public view returns(uint256) {
        uint256 daysPassed = (block.timestamp - (taxStart)) / (24*60*60);
        return daysPassed;
    }
    
    function taxPeriod() public view returns(uint256) {
        uint256 period = uint256(100) / (dailyTaxRate);
        return period;
    }
    
    function initiateSwap() public onlyOwner {
        require(IERC20(tokenTo).balanceOf(address(this)) >= tokenToTotal, "Target token balance too low");
        require(isInitiated == false, "Swap already initiated");
        isInitiated = true;
    }
    
    function withdrawTokens(address _token, address _to, uint256 _amount) public onlyOwner {
        IERC20 token = IERC20(_token);
        token.transfer(_to, _amount);
    }
    
    function setTaxEnabled(bool _newState) public onlyOwner {
        isTaxEnabled = _newState;
    }

    function changeStartTime(uint256 _newStart) public onlyOwner {
        require(block.timestamp > _newStart, "Cannot start swap at a future time!");
        taxStart = _newStart;
    }
}