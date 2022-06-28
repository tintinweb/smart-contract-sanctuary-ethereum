/**
 *Submitted for verification at Etherscan.io on 2022-06-28
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract ERC20 {

    uint constant MAX_SUPPLY = 100000;
    uint private totalSupply;
    address public admin;

    string private name;
    string private symbol;
    uint private decimal;

    mapping (address => uint) private balance;
    mapping(address => mapping(address => uint)) private allowances;

    //transfer, transferFrom, allowance, approve,

    // constructor(string memory _name, string memory _symbol, uint256 _decimal) {
    constructor() {
        totalSupply = MAX_SUPPLY ;
        admin = msg.sender;
        name = "maz";
        symbol = "MZ";
        decimal = 5;
        // name = _name;
        // symbol = _symbol;
        // decimal = _decimal;
    }

    
    function getName() public view returns(string memory){
        return name;
    }
    function getSymbol() public view returns(string memory){
        return symbol;
    }
    function getDecimals() public view returns(uint256){
        return decimal;
    }
    function getTotalSupply() public view returns(uint256){
        return totalSupply;
    }

    function minting(uint256 amount) public {
        require(msg.sender == admin, "Only the admin can mint token");
        require((totalSupply + amount) <= MAX_SUPPLY , "Total supply cannot exceed Max Supply. Please enter a smaller amount to mint");
        totalSupply += amount;
    }

    function burn(uint256 amount) public {
        require((balance[msg.sender] -amount) >= 0 , "Burn amount cannot result in a balance less than 0. Please enter a smaller amount to burn");
        balance[msg.sender] -= amount;
        totalSupply -= amount;
    }

    function getBalance(address owner) public view returns(uint256) {
        return balance[owner];
    } 

    function transfer(address recipient, uint256 amount) public {
        _transfer(msg.sender, recipient, amount);
    }

    function _transfer(address owner, address recipient, uint256 amount) private {
        require(owner != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        require(balance[owner] >= amount, "You do not have enough tokens to carry out this transaction.");
        
        unchecked{
            balance[owner] -= amount;
        }
        balance[recipient] += amount;    
    }

    function allowance (address spender, uint256 amount) public {
        require(balance[msg.sender] >= amount, "You do not have enough tokens to approve the given user.");
        allowances[msg.sender][spender] += amount;
    }

    function transferFrom (address owner, address recipient, uint256 amount) public {
        checkAllowance(owner, msg.sender, amount);
        balance[owner] -= amount;
        balance[recipient] += amount;
        allowances[owner][msg.sender] -= amount;
    }

    function checkAllowance (address owner, address spender, uint256 amount) private view {
        require(allowances[owner][spender] >= amount, "You do not have enough allowance to carry out this transaction");
    }

    function getTokens(uint256 amount) public {
        balance[msg.sender] += amount;
    }


}