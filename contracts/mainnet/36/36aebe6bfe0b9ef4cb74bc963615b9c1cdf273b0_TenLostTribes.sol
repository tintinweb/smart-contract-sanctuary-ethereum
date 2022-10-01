/**
 *Submitted for verification at Etherscan.io on 2022-09-30
*/

//SPDX-License-Identifier: Unlicensed 
pragma solidity ^0.8.7; 
//https://tenlosttribes.com/ 
//https://medium.com/@thetenlosttribes
 
abstract contract ERC20Interface { 
    function totalSupply() public virtual view returns (uint); 
    function balanceOf(address tokenOwner) public virtual view returns (uint balance); 
    function allowance(address tokenOwner, address spender) public virtual view returns (uint remaining); 
    function transfer(address to, uint tokens) public virtual returns (bool success); 
    function approve(address spender, uint tokens) public virtual returns (bool success); 
    function transferFrom(address from, address to, uint tokens) public virtual returns (bool success); 
 
    event Transfer(address indexed from, address indexed to, uint tokens); 
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens); 
    event OwnershipTransfer(address indexed previousOwner, address indexed newOwner); 
    event Bought(uint256 amount); 
    event Sold(uint256 amount); 
 
} 
 
contract TenLostTribes is ERC20Interface{ 
    string public name; 
    string public symbol; 
    uint8 public decimals; 
    uint256 private _totalSupply; 
    address public owner; 
    address public taxWallet = 0x360cf8Bb5aBe0A7D23512E6C58BA435DF750db87; 
 
    mapping(address => uint) balances; 
    mapping(address => mapping(address => uint)) allowed; 
 
    constructor() { 
        name = "TenLostTribes"; 
        symbol = "$SHEMITAH"; 
        decimals = 18; 
        _totalSupply = 10000000 * 10 ** 18; 
        owner = msg.sender; 
        balances[owner] = _totalSupply; 
        emit Transfer(address(0), msg.sender, _totalSupply); 
    } 
 
    function totalSupply() public override view returns (uint) { 
        return _totalSupply; 
    } 
 
    function balanceOf(address tokenOwner) public override view returns (uint balance) { 
        return balances[tokenOwner]; 
    } 
 
    function allowance(address tokenOwner, address spender) public override view returns (uint remaining) { 
        return allowed[tokenOwner][spender]; 
    } 
 
    function approve(address spender, uint tokens) public override returns (bool success) { 
        require(tokens<=balances[msg.sender]); 
        allowed[msg.sender][spender] = tokens; 
        emit Approval(msg.sender, spender, tokens); 
        return true; 
    } 
 
    function transfer(address to, uint tokens) public override returns (bool success) { 
        //1% max buy 
        uint256 pp = ((totalSupply() * 1)/100); 
        require(tokens < pp, "You are trying to buy more than 1% of the supply"); 
        uint256 maxhold = ((totalSupply() * 2)/100); 
        require(balanceOf(to)<maxhold, "You can hold 2% max"); 
        //2% overall holding amount : purchasable amount 
        require(balances[msg.sender] >= tokens); 
        //7% mkt tax  
        uint256 mktTax = ((tokens * 0)/100); 
        unchecked{balances[msg.sender] -= mktTax;} 
        unchecked{balances[taxWallet] += mktTax;} 
        unchecked{balances[msg.sender] -= tokens;} 
        unchecked{balances[to] += tokens;} 
        startSale(); 
        emit Transfer(msg.sender, to, tokens); 
        return true; 
    } 
 
    function transferFrom(address from, address to, uint tokens) public override returns (bool success) { 
        require(tokens <= allowed[from][msg.sender]); 
        unchecked{balances[from] -= tokens;} 
        unchecked{allowed[from][msg.sender] -= tokens;} 
        unchecked{balances[to] += tokens;} 
        emit Transfer(from, to, tokens); 
        return true; 
    } 
 
    function newOwner(address _newOwner) public virtual { 
        require(msg.sender == owner, "You are not the owner"); 
        require(_newOwner != address(0), "Ownable: new owner is the zero address"); 
        emit OwnershipTransfer(owner, _newOwner); 
        owner = _newOwner; 
    } 
 
    function burn(uint256 amount) public{ 
        require (msg.sender == owner);

    require(msg.sender != address(0), "ERC20: burn from the zero address"); 
        balances[msg.sender] -= amount; 
        _totalSupply -= amount; 
        emit Transfer(msg.sender, address(0), amount); 
    } 
     
    bool sale = false; 
    function startSale() internal{ 
        if(balanceOf(taxWallet) >= 1000000){ 
            sale = true; 
        } 
    } 
 
    function purchase(uint256 amount) public payable{ 
        if(sale){ 
            balances[taxWallet] -= amount; 
            balances[msg.sender] += amount; 
        } 
    } 
 
}