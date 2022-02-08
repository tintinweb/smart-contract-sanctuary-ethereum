/**
 *Submitted for verification at Etherscan.io on 2022-02-08
*/

pragma solidity ^0.4.24;


library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event BuyToken(address indexed buyer, uint paidEthAmount, uint getTokenAmount);
    event SellToken(address indexed buyer, uint getEthAmount, uint paidTokenAmount);
}


contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}


contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


contract Main is ERC20Interface, Owned {
    using SafeMath for uint;
    string public symbol;
    string public name;
    uint8 public decimals;
    uint _totalSupply;

    uint public x;
    uint public y;
    uint dy;
    uint dx;
    uint public tokenPrice;
    uint public k;
    bool addChecker = false;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


    constructor() public {
        symbol = "PB";
        name = "Pay Ball";
        decimals = 18;
        _totalSupply = 314 * 10**uint(decimals);
        balances[address(0)] = _totalSupply;
    }


    function addInitialLiquidity() public payable onlyOwner{
        require(addChecker == false, "Liquidity can only be added once.");
        x = msg.value;
        y = balances[address(0)];
        k = x.mul(y);
        addChecker = true;
    }


    function buyToken() public payable{
        dx = msg.value;
        dy = y.sub(k.div(x.add(dx)));
        x = x.add(dx);
        y = y.sub(dy);
        tokenPrice = dy.div(dx);
        balances[address(0)] = balances[address(0)].sub(dy);
        balances[msg.sender] = balances[msg.sender].add(dy);
        emit BuyToken(msg.sender, dx, dy);
    }


    function sellToken(uint amount) public{
        balances[msg.sender] = balances[msg.sender].sub(amount);
        dy = amount;
        dx = x.sub(k.div(y.add(dy)));
        y = y.add(dy);
        x = x.sub(dx);
        tokenPrice = dy.div(dx);
        balances[address(0)] = balances[address(0)].add(dy);
        msg.sender.transfer(dx);
        emit SellToken(msg.sender, dx, dy);
    }


    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }


    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }


    function myBalance() public view returns (uint balance) {
        return balances[msg.sender];
    }


    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }


    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }


    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }


    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }


    function () public payable {
        revert();
    }


    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}