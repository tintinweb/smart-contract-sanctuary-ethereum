/**
 *Submitted for verification at Etherscan.io on 2023-02-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyTokenICO {
    
    struct Token {
        string name;
        string symbol;
        uint8 decimals;
        uint256 totalSupply;
    }
    
    Token public token;
    uint256 public exchangeRate;
    uint256 public totalTokensForSale;
    bool public isOpen;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => bool) public investors;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Invest(address indexed investor, uint256 value);
    
    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _totalSupply, uint256 _exchangeRate, uint256 _amount) payable {
        require(msg.value == _amount, "Investment amount must match the amount parameter.");
        token = Token(_name, _symbol, _decimals, _totalSupply * 10 ** _decimals);
        exchangeRate = _exchangeRate;
        totalTokensForSale = _amount * exchangeRate * 10 ** token.decimals;
        balanceOf[msg.sender] = token.totalSupply - totalTokensForSale;
        isOpen = true;
        investors[msg.sender] = true;
        invest();
    }
    
    modifier isInvestor {
        require(investors[msg.sender] == true, "Only registered investors can call this function.");
        _;
    }
    
    function registerInvestor() public {
        require(isOpen == true, "ICO is closed.");
        investors[msg.sender] = true;
    }
    
    function unregisterInvestor() public {
        investors[msg.sender] = false;
    }
    
    function invest() public payable isInvestor {
        require(isOpen == true, "ICO is closed.");
        uint256 tokens = msg.value * exchangeRate * 10 ** token.decimals;
        require(tokens <= totalTokensForSale, "Not enough tokens available for sale.");
        totalTokensForSale -= tokens;
        balanceOf[msg.sender] += tokens;
        emit Transfer(address(this), msg.sender, tokens);
        emit Invest(msg.sender, msg.value);
    }
    
    function closeICO() public {
        require(msg.sender == address(this), "Only the contract owner can call this function.");
        isOpen = false;
    }
    
    function withdrawFunds() public payable{
        require(msg.sender == address(this), "Only the contract owner can call this function.");
        payable(msg.sender).transfer(address(this).balance);
    }
    
    function name() public view returns (string memory) {
        return token.name;
    }

    function symbol() public view returns (string memory) {
        return token.symbol;
    }

    function decimals() public view returns (uint8) {
        return token.decimals;
    }

    function totalSupply() public view returns (uint256) {
        return token.totalSupply;
    }
}