// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./IERC20.sol";
import "./IterableMapping.sol";

contract iUseArchBtwERC20Token is IERC20 {
    
    using IterableMapping for IterableMapping.Map;
    
    IterableMapping.Map private iBalance; 
    mapping(address => uint256) public reward;

    uint256 public totalSupply;
    mapping(address => mapping(address => uint256)) public allowance;
    string public name;
    string public symbol;
    uint256 public decimals;
    address public owner;
    
    constructor(){
        totalSupply = 1000 ether;
        name = "I Use Arch Btw Token";
        symbol = "IUAB";
        decimals = 18;
        owner = msg.sender;
        iBalance.set(owner, totalSupply);
    }
    
    receive() external payable {
        uint256 size = iBalance.size(); 
        address _addr;
        uint256 _bal;

        for (uint256 i = 0; i < size; i++) {
            _addr = iBalance.getKeyAtIndex(i);
            _bal = iBalance.get(_addr);
            if(_bal > 0){
                reward[_addr] += msg.value * _bal / totalSupply;
            }
        }
    }

    
    function getReward() public{
        require (reward[msg.sender] > 0, "You have no dividents to get");
        payable(msg.sender).transfer(reward[msg.sender]);
        reward[msg.sender] = 0;
    }
    

    function balanceOf(address addr) external view returns(uint256){
        return iBalance.get(addr);
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        iBalance.set(msg.sender, iBalance.get(msg.sender) - amount);
        iBalance.set(recipient, iBalance.get(recipient) + amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool) {
        allowance[sender][msg.sender] -= amount;
        iBalance.set(sender, iBalance.get(sender) - amount);
        iBalance.set(recipient, iBalance.get(recipient) + amount);
        return true;
    }
    

    
}