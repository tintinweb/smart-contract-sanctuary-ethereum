/**
 *Submitted for verification at Etherscan.io on 2022-02-25
*/

pragma solidity ^0.5.7;

contract ERC20Interface {
    function totalSupply() public view returns (uint _totalSupply);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tockenOwner, address indexed spender, uint tokens);
}

contract luckyToken is ERC20Interface{
    string public constant symbol = "HTKN";
    string public constant name = "Harm Token";
    uint8 public constant decimals = 1;
    uint private constant __totalSupply = 1000000000;
    
    mapping (address => uint) private __balanceOf;
    mapping (address => mapping (address => uint)) private __allowance;
    
    constructor() public {
        __balanceOf[msg.sender] = __totalSupply;
    }
    
    function totalSupply() view public returns (uint _totalSupply){
        _totalSupply = __totalSupply;
    }
    
    function balanceOf (address _addr) view public returns (uint balance){
        return __balanceOf[_addr];
    }
    
    function transfer (address _to, uint _value) public returns (bool success) {
        if (_value > 0 && _value <= balanceOf(msg.sender)) {
            __balanceOf[msg.sender] -= _value;
            __balanceOf[_to] += _value;
            return true;
        }
        return false;
    }
        
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        // if(__allowance[from][msg.sender] > 0 &&
        // tokens > 0 &&
        // __allowance[from][msg.sender] >= tokens) {
        //     __balanceOf[from] -= tokens;
        //     __balanceOf[to] += tokens;
        //     return true;
        // }
        return false;
    }
        
    function approve(address spender, uint tokens) public returns (bool success) {
        // __allowance[msg.sender][spender] = tokens;
        // return true;
        return false;
    }
        
    function allowance(address tokenOwner, address spender) view public returns (uint remaining) {
        return __allowance[tokenOwner][spender];
    }
}