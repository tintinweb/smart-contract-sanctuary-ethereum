/**
 *Submitted for verification at Etherscan.io on 2022-07-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

contract WorkshopARJ{
    mapping(address=>uint256) private balances;
    mapping(address=>string) private walletName;
    string private name;
    string private symbol;
    uint256 private totalSupply;
    
    constructor(string memory _name, string memory _symbol, uint256 _totalSupply){
        name = _name;
        symbol = _symbol;
        totalSupply = _totalSupply;
        balances[msg.sender] = _totalSupply;
    }
    function getName()public view returns (string memory){
        return name;
    }
    function getSymbol()public view returns (string memory){
        return symbol;
    }
    function getTotalSupply()public view returns (uint256){
        return totalSupply;
    }
    function getbalanceOf(address account)public view returns (uint256){
        return balances[account];
    }
    function transfer(address _to, uint256 amount)public{
        address owner = msg.sender;
        uint256 ownerBalance = balances[owner];
        require(ownerBalance >= amount);
        require(_to != owner);
        balances[owner] = ownerBalance - amount;
        balances[_to] += amount;
    }
    function setMywalletName(string memory _name)public{
        walletName[msg.sender] =_name;
    }
    function getWalletNmae(address _wallet)public view returns (string memory){
        if(bytes(walletName[_wallet]).length !=0){
            return walletName[_wallet];
        }
        return "No username";
    }
}