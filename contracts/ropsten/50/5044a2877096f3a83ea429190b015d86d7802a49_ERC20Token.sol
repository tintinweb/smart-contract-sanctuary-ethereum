/**
 *Submitted for verification at Etherscan.io on 2022-02-28
*/

//SPDX-License-Identifier: Unlincecsed
pragma solidity ^0.8.0;

interface ERC20Interface{

    function name() external view returns(string memory);
    function symbol() external view returns(string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns(uint);
    function balanceof(address tokenowner) external view returns(uint256 balance);
    function approve(address spender,uint256 amount) external returns(bool success);
    function transfer(address to, uint256 tokens) external returns(bool success);
    function transferFrom(address transfer, address to, uint256 tokens) external returns(bool success);

    event Transfer(address indexed from, address indexed to, uint256 indexed value);
    event Approve(address indexed owner, address indexed spender, uint256 indexed value);
}

contract ERC20Token is ERC20Interface{
    //State Variable 
    string private Name; // token name 
    string private Symbol; // token symbol
    uint256 private TotalSupply; // tokensuplly
    

    mapping(address => uint256) private balanceOf; // balanceof
    mapping(address => mapping(address => uint256)) public Allowance;

    // constructor 
    constructor(uint256 initialsupply, string memory tname, string memory tsymbol) {
        TotalSupply = initialsupply;
        Name = tname;
        Symbol = tsymbol;
        balanceOf[msg.sender] = initialsupply;
    }

    function name() public view override returns(string memory){
        return Name;
    }

    function symbol() public view override returns(string memory){
        return Symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 2;
    }

    function totalSupply() public view override returns(uint){
        return TotalSupply;
    }

    function balanceof(address tokenowner) public view override returns(uint balance){
        balance = balanceOf[tokenowner];
    }

    function transfer(address to, uint256 value) public override returns(bool success){
        // Account should have enough tokens to transfer
        require(balanceOf[msg.sender] >= value, "You do not have enough tokens to transfer");
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public override returns(bool success){
        Allowance[msg.sender][spender]=value;
        emit Approve(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public override returns(bool success){
        require(balanceOf[from] >= value, "Sender do not have enough tokens to transfer"); // Account should have enough tokens to transfer
        require(Allowance[from][msg.sender] >= value, "Allowance is not enough for transfer");//Check for approval
        
        Allowance[from][msg.sender] -= value;
        balanceOf[from] -= value;
        balanceOf[to] += value;

        emit Transfer(from, to, value);
        return true;
    }
}

// ERC20
// H.W 
// 1. Use functions name symbol totalsupply balanceof..
// 2. Also make the public variable private..
// 3. Take name and symbol from constructor parameter