/**
 *Submitted for verification at Etherscan.io on 2022-10-27
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

contract BlacklistableDAPSToken {
    string public name = "Blacklistable DAPS Token";
    string public symbol = "DAPS";
    uint256 public totalSupply = 1000000;
    address public owner;

    mapping(address => uint256) balances;
    mapping(address=>bool) isBlacklisted;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    constructor() {
        balances[msg.sender] = totalSupply;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function blackList(address _user) external onlyOwner {
        require(!isBlacklisted[_user], "user already blacklisted");
        isBlacklisted[_user] = true;
    }
    
    function removeFromBlacklist(address _user) external onlyOwner {
        require(isBlacklisted[_user], "user is not blacklisted");
        isBlacklisted[_user] = false;
    }

    function transfer(address to, uint256 amount) external {
        require(!isBlacklisted[msg.sender], "Sender is backlisted");
        require(!isBlacklisted[to], "Recipient is backlisted");
        require(balances[msg.sender] >= amount, "Not enough tokens");
        

        balances[msg.sender] -= amount;
        balances[to] += amount;

        emit Transfer(msg.sender, to, amount);
    }

    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    function viewBlacklist(address _user) external view returns (bool) {
        return isBlacklisted[_user];
    }

}