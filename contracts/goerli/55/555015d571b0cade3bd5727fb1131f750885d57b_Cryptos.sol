/**
 *Submitted for verification at Etherscan.io on 2022-08-02
*/

//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;
// ----------------------------------------------------------------------------
// EIP-20: ERC-20 Token Standard
// https://eips.ethereum.org/EIPS/eip-20
// -----------------------------------------

interface ERC20Interface {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function transfer(address to, uint tokens) external returns (bool success);
    
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


contract Cryptos is ERC20Interface{
    // life is hard, work hard, play hard
    // just for fun ok?
    string public name = "xxx Cryptos Test For Fun";
    string public symbol = "xxCOIN";
    uint public decimals = 18; //18 is very common
    uint public override totalSupply;
    
    address public founder;
    mapping(address => uint) public balances;
    
    mapping(address => mapping(address => uint)) allowed;
    
    
    constructor(){
        totalSupply = 100*380*25*100*100*10**decimals;
        /*funtest for fun dsfsafsdfasfasdfasdfasdfasf just tests the dattadfwesefasefasefaesfaefa
        life is so hard?*/
        founder = msg.sender;
        balances[founder] = totalSupply;
    }
    
    
    function balanceOf(address tokenOwner) public view override returns (uint balance){
        return balances[tokenOwner];
    }
    
    
    function transfer(address to, uint tokens) public override returns(bool success){
        require(balances[msg.sender] >= tokens);
        
        balances[to] += tokens;
        balances[msg.sender] -= tokens;
        emit Transfer(msg.sender, to, tokens);
        
        return true;
    }
    
    
    function allowance(address tokenOwner, address spender) view public override returns(uint){
        return allowed[tokenOwner][spender];
    }
    
    
    function approve(address spender, uint tokens) public override returns (bool success){
        require(balances[msg.sender] >= tokens);
        require(tokens > 0);
        
        allowed[msg.sender][spender] = tokens;
        
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    
    function transferFrom(address from, address to, uint tokens) public override returns (bool success){
         require(allowed[from][msg.sender] >= tokens);
         require(balances[from] >= tokens);
         
         balances[from] -= tokens;
         allowed[from][msg.sender] -= tokens;
         balances[to] += tokens;
 
         emit Transfer(from, to, tokens);
         
         return true;
     }
}