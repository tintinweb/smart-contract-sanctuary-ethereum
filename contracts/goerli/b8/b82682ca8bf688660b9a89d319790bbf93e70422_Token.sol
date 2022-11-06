/**
 *Submitted for verification at Etherscan.io on 2022-11-06
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;


contract TokenMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "TokenMath: addition overflow");
        return c;    }

    function safeAdd(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;}
            uint256 c = a * b;
            require(c / a == b, "TokenMath: multiplication overflow");
            return c;}

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "TokenMath: division by zero");
        uint256 c = a / b;
        return c;    }
}

contract Token is TokenMath {
    address public pool;
    address consul;

    string public symbol;
    string public name;

    uint8 public decimals;
    uint _totalSupply;
    uint public _poolSupply;
    bool public _poolSupplySent;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    constructor() {
        symbol = "3DAO";
        name = "3DaoToken";
        decimals = 18;
        _totalSupply = 100_000_000e18; //100 million
        _poolSupply = 20_000_000e18;  //20 million
        balances[msg.sender] = _totalSupply;
        consul = msg.sender;
        _poolSupplySent = false;

    }
    modifier onlyconsul(){
        require(msg.sender == consul, "You are not the consul");
        _;
    }
    modifier onlyNoPool(){
        require(_poolSupplySent == false, "Pool supply already sent");
        _;
    }
    function activatePool(address _pool) public onlyconsul onlyNoPool{
      transfer(_pool, _poolSupply);
      pool = _pool;
      _poolSupplySent = true;
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply - balances[address(0)];
    }
    function balanceOf(address tokenOwner) public  view returns (uint balance) {
        return balances[tokenOwner];
    }
    function transfer(address receiver, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[receiver] = safeAdd(balances[receiver], tokens);
        emit Transfer(msg.sender, receiver, tokens);
        return true;
    }
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    function transferFrom(address sender, address receiver, uint tokens) public returns (bool success) {
        balances[sender] = safeSub(balances[sender], tokens);
        allowed[sender][msg.sender] = safeSub(allowed[sender][msg.sender], tokens);
        balances[receiver] = safeAdd(balances[receiver], tokens);
        emit Transfer(sender, receiver, tokens);
        return true;
    }
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }





}